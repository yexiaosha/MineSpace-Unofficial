package com.minespace.unofficial.galacticraft;

import io.netty.buffer.ByteBuf;
import net.minecraft.entity.player.EntityPlayerMP;
import net.minecraftforge.fml.common.network.NetworkRegistry;
import net.minecraftforge.fml.common.network.simpleimpl.IMessage;
import net.minecraftforge.fml.common.network.simpleimpl.IMessageHandler;
import net.minecraftforge.fml.common.network.simpleimpl.MessageContext;
import net.minecraftforge.fml.common.network.simpleimpl.SimpleNetworkWrapper;
import net.minecraftforge.fml.relauncher.Side;

/**
 * One packet, and it is the only thing this mod needs to say to a server.
 *
 * <p>The star map is drawn on the client and the rocket lives on the server, so "point my rocket at that body" has to
 * cross the line. One int - the dimension id - which the server then validates with
 * {@link MinespaceRocketTarget#apply}: a client is never trusted to decide that it may go somewhere, and the
 * validation (research data, rocket, tier, fuel) reads state only the server can see.</p>
 */
public final class MinespaceNetwork {

    public static final SimpleNetworkWrapper CHANNEL =
            NetworkRegistry.INSTANCE.newSimpleChannel(com.minespace.unofficial.Minespace.MOD_ID);

    private MinespaceNetwork() {
    }

    public static void register() {
        CHANNEL.registerMessage(RocketTargetMessage.Handler.class, RocketTargetMessage.class, 0, Side.SERVER);
        // The other direction only exists on a client: "you are in orbit, choose a destination" is a message the
        // server sends, and the code that acts on it draws a screen. Registered conditionally so a dedicated server
        // never loads it.
        if (net.minecraftforge.fml.common.FMLCommonHandler.instance().getSide().isClient()) {
            CHANNEL.registerMessage(OpenStarMapMessage.ClientHandler.class, OpenStarMapMessage.class, 1, Side.CLIENT);
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
                com.minespace.unofficial.gtceu.MinespaceStarMapScreen.openForChoice();
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
                // The answer goes to the chat: a refusal has to say why, and a confirmation has to say that the launch
                // is now the player's to press.
                MinespaceRocketTarget.tell(player,
                        MinespaceRocketTarget.apply(player, message.dimensionId, message.inFlight));
                return null;
            }
        }
    }
}
