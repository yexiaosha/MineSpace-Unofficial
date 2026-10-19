package com.minespace.unofficial.navigation;

import io.netty.buffer.ByteBuf;
import net.minecraft.entity.player.EntityPlayerMP;
import net.minecraftforge.fml.common.network.NetworkRegistry;
import net.minecraftforge.fml.common.network.simpleimpl.IMessage;
import net.minecraftforge.fml.common.network.simpleimpl.IMessageHandler;
import net.minecraftforge.fml.common.network.simpleimpl.MessageContext;
import net.minecraftforge.fml.common.network.simpleimpl.SimpleNetworkWrapper;
import net.minecraftforge.fml.relauncher.Side;

/**
 * The three packets the star map and the rocket need to say to each other.
 *
 * <p>The map is drawn on the client and the rocket lives on the server, so "point my rocket at that body" has to cross
 * the line. One int - the dimension id - which the server then validates with {@link MinespaceRocketTarget#apply}: a
 * client is never trusted to decide that it may go somewhere, and the validation (research data, rocket, tier, fuel)
 * reads state only the server can see. The two server-to-client messages are the other half of the same
 * conversation: "you are in orbit, choose" and "the move is happening, hold on".</p>
 *
 * <p>Every handler that touches the world or a screen schedules its work onto the right thread first (6ez, 6f): a
 * simple channel delivers on the network thread, and both a dimension change and a GUI are main-thread work.</p>
 */
public final class MinespaceNetwork {

    private static final org.apache.logging.log4j.Logger LOG =
            org.apache.logging.log4j.LogManager.getLogger("minespace_navigation");

    public static final SimpleNetworkWrapper CHANNEL =
            // The channel name is frozen with the rest of the content namespace: it is a wire name shared with
            // clients, not the mod id (see MinespaceContent).
            NetworkRegistry.INSTANCE.newSimpleChannel(com.minespace.unofficial.MinespaceContent.NAMESPACE);

    private MinespaceNetwork() {
    }

    public static void register() {
        CHANNEL.registerMessage(RocketTargetMessage.Handler.class, RocketTargetMessage.class, 0, Side.SERVER);
        // The other direction only exists on a client: "you are in orbit, choose a destination" and "the move is
        // happening" are messages the server sends, and the code that acts on them draws a screen or holds one.
        // Registered conditionally so a dedicated server never loads them.
        if (net.minecraftforge.fml.common.FMLCommonHandler.instance().getSide().isClient()) {
            CHANNEL.registerMessage(OpenStarMapMessage.ClientHandler.class, OpenStarMapMessage.class, 1, Side.CLIENT);
            CHANNEL.registerMessage(TeleportingMessage.ClientHandler.class, TeleportingMessage.class, 2, Side.CLIENT);
        }
    }

    /**
     * Server to client: "the rocket has left the atmosphere - open the star map and pick somewhere."
     *
     * <p>This is Galacticraft's own flow with our map in it: GC's ascent ends with a destination choice, GC's version
     * draws its celestial screen, and this one draws the pack's star map instead. Nothing else about the flight
     * changes.</p>
     */
    public static final class OpenStarMapMessage implements IMessage {

        public OpenStarMapMessage() {
        }

        @Override
        public void fromBytes(ByteBuf buf) {
        }

        @Override
        public void toBytes(ByteBuf buf) {
        }

        public static final class ClientHandler implements IMessageHandler<OpenStarMapMessage, IMessage> {

            @Override
            public IMessage onMessage(OpenStarMapMessage message, MessageContext ctx) {
                // The screen is the client's business and the client thread's: a simple channel delivers its messages on
                // the network thread (6ez), and a GUI opened from there is a GUI opened behind the game's back.
                net.minecraft.client.Minecraft.getMinecraft().addScheduledTask(new Runnable() {
                    @Override
                    public void run() {
                        com.minespace.unofficial.navigation.MinespaceStarMapScreen.openForChoice();
                    }
                });
                return null;
            }
        }
    }

    /** Client to server: "aim at this body". */
    public static final class RocketTargetMessage implements IMessage {

        private int dimensionId;
        /** True when this is the in-orbit choice ("take me there now") rather than an aim made on the ground. */
        private boolean inFlight;

        public RocketTargetMessage() {
        }

        public RocketTargetMessage(int dimensionId) {
            this.dimensionId = dimensionId;
        }

        public RocketTargetMessage(int dimensionId, boolean inFlight) {
            this.dimensionId = dimensionId;
            this.inFlight = inFlight;
        }

        @Override
        public void fromBytes(ByteBuf buf) {
            dimensionId = buf.readInt();
            inFlight = buf.readBoolean();
        }

        @Override
        public void toBytes(ByteBuf buf) {
            buf.writeInt(dimensionId);
            buf.writeBoolean(inFlight);
        }

        public static final class Handler implements IMessageHandler<RocketTargetMessage, IMessage> {

            @Override
            public IMessage onMessage(RocketTargetMessage message, MessageContext ctx) {
                EntityPlayerMP player = ctx.getServerHandler().player;
                // **On the server thread.** A simple channel hands the message to the network thread - the thread named
                // in the log of 6ez was "Netty Server IO #1" - and everything below this line touches the world:
                // changeDimension loads the destination, generates its spawn chunks and populates the ore in them.
                // Doing that off-thread raced the server's own chunk generation and ended in "Already decorating!!",
                // which Forge treats as fatal: it terminated the connection and the owner's client was back at the
                // main menu with no crash report to read.
                player.mcServer.addScheduledTask(new Runnable() {
                    @Override
                    public void run() {
                        try {
                            // The answer goes to the chat: a refusal has to say why, and a confirmation has to say that
                            // the launch is now the player's to press.
                            MinespaceRocketTarget.tell(player,
                                    MinespaceRocketTarget.apply(player, message.dimensionId, message.inFlight));
                        } catch (Throwable t) {
                            // A failure here is a bug, not a disconnection: log it and leave the player where they are,
                            // with the rocket still theirs to relaunch.
                            LOG.error("star map: handling a destination request from {} failed", player.getName(), t);
                        }
                    }
                });
                return null;
            }
        }
    }

    /**
     * Server to client: "the move is happening - put up Galacticraft's teleporting screen".
     *
     * <h2>Why this exists (6g)</h2>
     *
     * <p>An arrival used to show vanilla's "Downloading terrain" and nothing else, while Galacticraft's own runs show
     * its progress screen. That screen is not a re-implementation: {@code GuiTeleporting}'s constructor registers
     * itself in {@code TickHandlerClient.teleportingGui}, the client tick handler forces it as the current screen until
     * the new world is ready, and the screen clears itself when it sees the destination dimension. Constructing it is
     * the whole mechanism, so this packet carries the destination and the client constructs it.</p>
     */
    public static final class TeleportingMessage implements IMessage {

        private int dimensionId;

        public TeleportingMessage() {
        }

        public TeleportingMessage(int dimensionId) {
            this.dimensionId = dimensionId;
        }

        @Override
        public void fromBytes(ByteBuf buf) {
            dimensionId = buf.readInt();
        }

        @Override
        public void toBytes(ByteBuf buf) {
            buf.writeInt(dimensionId);
        }

        public static final class ClientHandler implements IMessageHandler<TeleportingMessage, IMessage> {

            @Override
            public IMessage onMessage(TeleportingMessage message, MessageContext ctx) {
                net.minecraft.client.Minecraft.getMinecraft().addScheduledTask(new Runnable() {
                    @Override
                    public void run() {
                        // Ours by default (6h); Galacticraft's own screen is what the setting's other answer gives.
                        // **Shown, not merely constructed.** The constructor registers the screen with Galacticraft's
                        // tick handler, which then forces it as currentScreen every tick - but a screen that was never
                        // passed to displayGuiScreen has no mc, width or fontRenderer, and its first tick died with a
                        // NullPointerException (6i). Showing it once initialises it; the tick handler keeps it alive.
                        net.minecraft.client.Minecraft mc = net.minecraft.client.Minecraft.getMinecraft();
                        if (MinespaceNavigationSettings.ownTeleportScreen) {
                            mc.displayGuiScreen(new MinespaceTeleportingScreen(message.dimensionId));
                        } else {
                            mc.displayGuiScreen(
                                    new micdoodle8.mods.galacticraft.core.client.gui.screen.GuiTeleporting(message.dimensionId));
                        }
                    }
                });
                return null;
            }
        }
    }
}
