# The planet vein table - the single source of truth the vein files are generated from.
#
# Why a table, and why this shape:
#
#   * The GTCEu galaxy plan (section 5.4) defines a vein as primary / secondary / byproduct ores plus
#     a weight and an environment preference, wants 5..8 of them per body, and requires every one to
#     carry a geological reason. That is exactly one row per vein here.
#   * The plan's acceptance criterion "no ore generates twice and none is missing" is a property of
#     the *assignment*, and 6cx measured that hand-written assignment had drifted into 74 pairs of
#     duplicate (dimension, name) - a vein file edited on one body and forgotten on another. Here the
#     assignment is derived, so it cannot drift.
#   * A vein's share of a body's list is its `weight` divided by the sum of that body's weights, so
#     the numbers below read as "how often, relative to its neighbours on the same body".
#
# Naming: a vein name is shown to the player. GregTech's JEI page builds its title with
# `makePrettyName`, which replaces dots and underscores with spaces and does not consult a lang file,
# so the name has to *read* as a title: "Mare Ilmenite Vein", not "gregtech.veins.ore.bauxite".
# A name is unique per definition, and the generator refuses to let one body carry it twice.
#
# `Reason` is the geological justification the plan asks for. It is also written into the file's
# `description` field, so it travels with the data.
@{

    # A region is what makes a hundred and ten bodies affordable. The seven layers of the plan's
    # universe (section 1.1) each own a *suite*: the variants every body in that layer carries. A body
    # then needs two fields - its region and, if it is one of the bodies the plan names, a signature -
    # and adding body 101 is one row rather than five to eight.
    #
    # The solar system is deliberately NOT modelled this way: twenty-five bodies justify their own
    # geology cards, and writing them taught the shape the regions below are built from. Regions are
    # for the ninety bodies where a card each would be busywork, which is what the plan's stage three
    # asks for ("the template copied to a second planet in under a day").
    Regions = @{
        # The universal base: the five veins every body outside the solar system carries, so that no
        # landing is a dead end and a player who flies out always has the ordinary materials locally.
        # It is a suite rather than a layer - no stage, no bodies of its own - and the layers below
        # include it.
        base = @{
            Display  = 'Universal base'
            Note     = 'The ordinary five: silicate, iron-nickel, sulphide, rare earth, volatile.'
            Variants = @(
                'frontier_silicate'
                'frontier_iron_nickel'
                'frontier_sulfide'
                'frontier_rare_earth'
                'frontier_volatile'
            )
        }

        nearby_systems = @{
            Display  = 'Nearby Systems'
            Layer    = 'IV - the first systems after the solar system (Proxima, Barnard, Tau Ceti)'
            Stage    = 4
            Voltage  = 'IV'
            Includes = @('base')
            Note     = 'No delta yet: these four bodies are served by the base suite plus their signatures.'
        }

        # --- the layers that are planned but have no bodies yet -------------------------------------
        #
        # A planned layer is a note in the table rather than a design, and that is deliberate: naming
        # its veins before its bodies exist would be inventing content. What is fixed here is the
        # *theme* each layer's delta has to express, taken from the plan's own table 2-1, and the
        # generator reports these so the plan sits where the next body will be added.
        # The universal base is included by every layer, so a body only ever needs a delta of two to
        # four veins plus, if the plan names it, one signature.
        mid_systems = @{
            Display  = 'Mid Systems'
            Layer    = 'LuV~ZPM - TRAPPIST-1 and the Gliese systems, ruins I and II, gas giant harvesting'
            Stage    = 5
            Voltage  = 'LuV~ZPM'
            IdRange  = '-2100..-2199'
            Bodies   = '14 in PLANET-CATALOG, all landable: the seven TRAPPIST-1 planets, the Gliese systems, 55 Cancri e, HD 219134 b, HD 40307 g, 51 Pegasi b'
            Includes = @('base')
            Variants = @('heavy_refractory')
            Note     = 'Delta: the heavy refractory sulphides, which is what a body this far out is worth mining for. Signatures carry the ruin-delivered ore (TRAPPIST-1 e) and the two gas giants are deliberately absent - Gliese 876 b and 51 Pegasi b have no surface, so they belong to atmospheric harvesting, not to a vein.'
        }

        far_systems = @{
            Display  = 'Far Systems'
            Layer    = 'UV - Kepler-452b and kin, time observation, ruins III'
            Stage    = 6
            Voltage  = 'UV'
            IdRange  = '-2200..-2299'
            Bodies   = '14 in PLANET-CATALOG, 11 landable: the Kepler field, K2-18 b, and PSR B1257+12 b; Betelgeuse, Boyajian''s Star and the Vela Pulsar are observation targets'
            Includes = @('base')
            Planned  = $true
            Note     = 'Delta theme: crystals and the exotic - bodies that are already dead, and what observing them yields.'
        }

        deep_space = @{
            Display  = 'Deep Space'
            Layer    = 'UHV - neutron stars, black holes, the Dyson sphere stages'
            Stage    = 7
            Voltage  = 'UHV'
            IdRange  = '-2300..-2349'
            Bodies   = '14 in PLANET-CATALOG, 3 landable: Kepler-70 b and c, and PSR B1620-26 b (Methuselah). The rest are the galactic centre, black holes and clusters - observation only'
            Includes = @('base')
            Planned  = $true
            Note     = 'Delta theme: extreme-matter veins. This is also where Draconic Evolution''s draconium belongs (6de route 2, exotic).'
        }

        ultra_deep = @{
            Display  = 'Ultra-deep Space'
            Layer    = 'UHV+ - the Local Group and the Virgo Cluster, ruins IV'
            Stage    = 8
            Voltage  = 'UHV+'
            IdRange  = '-2350..-2399'
            Bodies   = '13 in PLANET-CATALOG, none landable: galaxies, nebulae and M87*. Wreckage of type IV, and nothing to mine'
            Includes = @('base')
            Planned  = $true
            Note     = 'No delta: a layer with no landable body needs no vein. It exists here so the table and the catalog agree on the layers.'
        }

        unknown = @{
            Display  = 'Unknown Systems'
            Layer    = 'UHV+ - beyond the galaxy gates: ancient galaxies, quasars, the cosmic web, the CMB'
            Stage    = 8
            Voltage  = 'UHV+'
            IdRange  = '-2400..-2449'
            Bodies   = '15 in PLANET-CATALOG, none landable: quasars, the CMB, gravitational waves. Observation only, which is the point of the layer'
            Includes = @('base')
            Planned  = $true
            Note     = 'No delta, for the same reason as ultra-deep. Two of the fifteen are not at a distance at all - Oumuamua and Borisov are visitors, and they are inside the solar system.'
        }
    }

    Bodies = @{
        moon = @{
            Display     = 'Moon'
            DimensionId = -28
            Card        = @(
                'A tidally locked silicate body with almost no atmosphere. The magma ocean of 4.5 Ga'
                'differentiated into two crusts: aluminium-rich, iron-poor anorthosite highlands and'
                'ilmenite-rich mare basalt, roughly half the surface each.'
                'Four billion years of impacts then mixed iron-nickel metal, platinum-group metals and'
                'a little diamond into the regolith as impact breccia and melt sheets.'
                'No water and no plate tectonics, so every vein is either primary differentiation or'
                'impact - and they all sit in the top 40 blocks, which is what the height bands say.'
            )
        }

        # The nearby systems - the plan's stage-three sample, and the first bodies whose cards are
        # real rather than provisional. They carry the universal base (their region) plus a delta that
        # expresses the body's actual environment, plus one signature.
        #
        # The signatures are not decoration: they are where the closure checklist's *gap list* gets
        # filled, which is what plan 2.2 asks for ("any gap is filled by a vein variant"). Ten of the
        # twenty materials that had no source anywhere now have one - zircon, pyrochlore, columbite,
        # gallite, vinteum, opal, jasper, witherite, celestine, rhodocrosite - each placed where its
        # real mineralogy makes sense.
        barnarda_c = @{
            Display     = 'Barnard''s Star b'
            DimensionId = -1030
            Folder      = 'barnarda'
            Region      = 'nearby_systems'
            Signature   = 'barnarda_onyx'
            Card        = @(
                'Galaxy Space calls this body "Barnarda C", which is not a real name; PLANET-CATALOG maps'
                'the dimension -1030 to Barnard''s Star b, 5.96 light years away and confirmed in 2024.'
                'The largest of Barnard''s Star''s planets: rock and ice around a red dwarf, cold'
                'enough that water never leaves, and old enough that nothing has stirred it in'
                'billions of years.'
                'Its crust is the system''s ordinary basalt, and its signature is the pack''s own'
                'onyx - the one material here that no other body carries.'
            )
        }
        barnarda_c1 = @{
            Display     = 'Barnard''s Star c'
            DimensionId = -1031
            Folder      = 'barnarda'
            Region      = 'nearby_systems'
            Signature   = 'barnarda_pegmatite'
            Card        = @(
                'Galaxy Space calls this body "Barnarda C1"; PLANET-CATALOG maps -1031 to Barnard''s'
                'Star c, a 0.335-Earth-mass planet on a 4.12-day orbit, confirmed in 2025.'
                'The smaller neighbour, and the one that cooled fast enough to fractionate: its last'
                'magma, water-rich and chemically lazy, concentrated what did not fit anywhere else.'
                'That is why niobium, tantalum and gallium are found here and nowhere in the solar'
                'system - a pegmatite is what a planet''s leftovers make.'
            )
        }
        barnarda_c2 = @{
            Display     = 'Barnard''s Star d'
            DimensionId = -1032
            Folder      = 'barnarda'
            Region      = 'nearby_systems'
            Signature   = 'barnarda_ruin_cache'
            Card        = @(
                'Galaxy Space calls this body "Barnarda C2"; PLANET-CATALOG maps -1032 to Barnard''s'
                'Star d - 0.263 Earth masses, a 2.34-day orbit, wrapped around its star.'
                'The outermost of the three, and the first body in this pack where the ore is not'
                'geology at all: vinteum, opal and jasper sit in a cache on a world that could not'
                'have made them.'
                'That is plan 2.2''s artificial route doing its job - the ore is what was left here,'
                'and the I-type ruins stage three injects are the visible half of the same story.'
            )
        }
        proxima_b = @{
            Display     = 'Proxima B'
            DimensionId = -1025
            Region      = 'nearby_systems'
            Signature   = 'proxima_zircon'
            Card        = @(
                'Tidally locked inside the habitable zone of a flare star: one face always toward'
                'Proxima, one face always away, and every few hours an X-ray flare strips a little'
                'more of whatever atmosphere it has.'
                'The only liquid water is the substellar sea on the day side; the night side is ice.'
                'The regolith is baked rather than weathered - sulphur, nitrates and tellurium, the'
                'chemistry of a surface under a star that will not leave it alone.'
                'The signature is zircon: this is the oldest, most re-melted crust in the pack, and'
                'zircon with its niobium-rare-earth companions only survives where rock has been'
                'melted and cooled many times over.'
            )
        }
        tauceti_f = @{
            Display     = 'Tau Ceti F'
            DimensionId = -1338
            Region      = 'nearby_systems'
            Signature   = 'tauceti_carbonate'
            Card        = @(
                'A super-Earth around an old, metal-poor star with a debris disc around it: a big'
                'planet with a deep interior, a long history, and enough water to have made'
                'carbonates and sulphates rather than merely rock.'
                'Deep enough that diamond is a rock-forming mineral here, not a gem, which is what'
                'its pressure vein says.'
                'Its signature is the evaporite suite - witherite, celestine and rhodocrosite - the'
                'carbonates of a crust that has been wet and dry many times over.'
            )
        }

        europa = @{
            Display     = 'Europa'
            DimensionId = -1015
            Card        = @(
                'An ice shell over a global ocean over a rocky mantle and an iron core - the most'
                'layered body in the solar system, and the reason its veins are a stack rather than'
                'a scatter.'
                'Tidal heating from Jupiter keeps the ocean liquid, so the rock and the water meet:'
                'that boundary is where the sulphides and the platinum-group metal come from, and'
                'the brine in the shell is what is left of the same water.'
                'The surface is ice, which the crystal vein stands in for - the pack has no ice ore.'
            )
        }

        mars = @{
            Display     = 'Mars'
            DimensionId = -29
            Card        = @(
                'A smaller, colder Earth that lost its air: basaltic plains, the largest volcanoes in'
                'the system, and iron oxide dust over everything - which is why the surface is red and'
                'why the iron veins here oxidise rather than rust away.'
                'Its water history is written in hydrated sulphates and clays, laid down when the'
                'northern ocean still existed; the salts are what stayed behind when it went.'
                'Desh is this pack''s own Martian metal - Galacticraft''s Mars tier expects it, so the'
                'ore has to be here whatever the geology would say.'
            )
        }

        venus = @{
            Display     = 'Venus'
            DimensionId = -31
            Card        = @(
                'A runaway greenhouse: 460 degrees at the surface, ninety times Earth''s pressure, and'
                'a cloud deck of sulphuric acid - the only place in the system where ore forms in the'
                'sky, which is what the acid-cloud vein''s height band says.'
                'The surface is basaltic, resurfaced by volcanism so recently that almost nothing is'
                'old, so the sulphides are primary and shallow and the gems are what high pressure'
                'made of the same rock.'
                'The evaporites are the last of the oceans it used to have.'
            )
        }

        gs_venus = @{
            Display     = 'GS Venus'
            DimensionId = -1006
            Folder      = 'venus'
            Card        = @(
                'Galaxy Space''s Venus is the same body as Galacticraft''s, so it carries the same'
                'veins rather than a set of its own - the one place in the solar system where two'
                'dimension ids are deliberately one geology.'
            )
        }

        asteroids = @{
            Display     = 'Asteroids'
            DimensionId = -30
            Card        = @(
                'The belt never became a planet: planetesimals that are still metal, still rock and'
                'still carbonaceous, with no atmosphere and no differentiation to sort them out.'
                'That is why the metals are native rather than in veins proper, why the platinum group'
                'is reachable at all, and why naquadah belongs out here rather than on a world.'
            )
        }

        phobos = @{
            Display     = 'Phobos'
            DimensionId = -1012
            Card        = @(
                'A captured planetesimal, not a moon that formed here: the same undifferentiated'
                'material as the belt, which is why it carries the belt''s veins rather than Mars''.'
                'Its whole reason to exist in the progression is being the cheap first stop.'
            )
        }
        deimos = @{
            Display     = 'Deimos'
            DimensionId = -1013
            Card        = @(
                'The smaller of the two captured bodies at Mars, with the same carbonaceous and'
                'metallic mix as Phobos - regolith over unaltered planetesimal.'
            )
        }

        ceres = @{
            Display     = 'Ceres'
            DimensionId = -1007
            Card        = @(
                'The belt''s one dwarf planet, and the only body out there with a water history:'
                'briny subsurface reservoirs that left carbonates and salts behind.'
                'A rock-and-ice interior under a carbonaceous crust, so it carries the icy suite'
                'plus the carbonate vein that is its signature.'
            )
        }

        pluto = @{
            Display     = 'Pluto'
            DimensionId = -1008
            Card        = @(
                'A dwarf planet of rock and nitrogen ice, with the reddish tholins that give it its'
                'colour - organics made by sunlight hitting methane, not by life.'
                'Far enough out that the volatiles never boiled away, which is why its suite is the'
                'icy one plus a tholin vein.'
            )
        }

        kuiper_belt = @{
            Display     = 'Kuiper Belt'
            DimensionId = -1009
            Card        = @(
                'The far edge of the solar system: the same icy planetesimals as Pluto, at the'
                'distance where naquadah first appears in this pack.'
                'Icy suite plus an exotic vein, and the second place naquadah can be had.'
            )
        }

        haumea = @{
            Display     = 'Haumea'
            DimensionId = -1023
            Card        = @(
                'An icy dwarf planet spun so fast by a collision that it is an ellipsoid, with a ring'
                'and two moons of its own.'
                'Crystalline ice over rock, and nothing else remarkable - the icy suite, nothing more.'
            )
        }

        triton = @{
            Display     = 'Triton'
            DimensionId = -1021
            Card        = @(
                'A captured Kuiper Belt object orbiting Neptune backwards, with nitrogen and methane'
                'frosts and cryovolcanic vents.'
                'Same material as the belt it came from, so the icy suite applies unchanged.'
            )
        }

        miranda = @{
            Display     = 'Miranda'
            DimensionId = -1024
            Card        = @(
                'A small Uranian moon whose terrain was pulled apart and reassembled by tidal'
                'heating - ice and rock in the same proportions, wildly rearranged.'
                'The icy suite, with no signature of its own yet.'
            )
        }

        callisto = @{
            Display     = 'Callisto'
            DimensionId = -1022
            Card        = @(
                'The one large moon that never differentiated: ice and rock mixed evenly all the way'
                'through, outside Jupiter''s worst radiation.'
                'No core to mine and no ocean to tap, so the icy suite is the honest answer.'
            )
        }

        ganymede = @{
            Display     = 'Ganymede'
            DimensionId = -1016
            Card        = @(
                'The largest moon in the system and the only one with a magnetic field of its own:'
                'a metal core, a rocky mantle, an ocean, and an ice shell - Europa''s stack, thicker.'
            )
        }

        enceladus = @{
            Display     = 'Enceladus'
            DimensionId = -1017
            Card        = @(
                'A small icy moon spraying its ocean into space through the tiger stripes at its'
                'south pole - the brine vein here is the same water those plumes are made of.'
            )
        }

        io = @{
            Display     = 'Io'
            DimensionId = -1014
            Card        = @(
                'The most volcanically active body in the system, squeezed by Jupiter until it turns'
                'itself inside out: no impact craters, because nothing survives on the surface.'
                'Everything here is volcanic - sulphur and its compounds first, then the ultramafic'
                'lava the sulphur comes out of, then the alkali salts the plumes leave behind.'
                'No water and no ice, so nothing in Io''s suite is volatile in the usual sense.'
            )
        }

        titan = @{
            Display     = 'Titan'
            DimensionId = -1018
            Card        = @(
                'The only moon with an atmosphere worth the name, and the only body other than Earth'
                'with liquid on its surface - lakes of methane and ethane, not water.'
                'Its chemistry is hydrocarbon and nitrogen, which the pack represents with oilsands,'
                'coal and graphite, and with niter for the nitrogen it is famous for.'
                'Underneath all that, an icy shell over a rocky interior, so the ice and silicate'
                'veins are here too.'
            )
        }

        mercury = @{
            Display     = 'Mercury'
            DimensionId = -1005
            Card        = @(
                'An iron core that is most of the planet, with a thin silicate shell over it - the'
                'least oxidised rock in the system, because there was never enough air to rust it.'
                'Four billion years of impacts delivered platinum-group metal and left graphite-rich'
                'material behind, which is why the surface is dark.'
                'No atmosphere and no water: everything here is primary or impact, and none of it'
                'is volatile except the sulphides Mercury turns out to be surprisingly rich in.'
            )
        }

        # --- layer 3, the mid systems (stage 5, LuV~ZPM), PLANET-CATALOG ids -2100 and up ----------
        #
        # Every one of these is Pending: PLANET-CATALOG assigns the dimension ids, but no such dimension
        # exists in the game yet, and generating vein files for them would put planets nobody can reach
        # into JEI. The cards below are the design; the files appear the day the planet does.
        #
        # Gliese 876 b and 51 Pegasi b are in the catalog's 14 but not here: a gas giant has no surface,
        # so it belongs to the plan's atmospheric-harvesting system (stage 5's own theme), not to a vein.
        trappist_1b = @{
            Display     = 'TRAPPIST-1 b'
            DimensionId = -2100
            Region      = 'mid_systems'
            Pending     = $true
            Card        = @(
                'The innermost of seven Earth-sized planets around an M8 dwarf: 398 K, tidally locked, and'
                'almost certainly stripped of whatever atmosphere it had.'
                'No signature of its own - the layer delta is the whole story here, which the catalog''s'
                'own note says is the hottest and most cooked of the seven.'
            )
        }
        trappist_1c = @{
            Display     = 'TRAPPIST-1 c'
            DimensionId = -2101
            Region      = 'mid_systems'
            Signature   = 'runaway_greenhouse'
            Pending     = $true
            Card        = @(
                'The catalog calls it a Venus-style runaway greenhouse, and that is the design brief:'
                '340 K, in resonance with b, and the sulphur and salt chemistry of a planet that never'
                'cooled enough to keep its water.'
            )
        }
        trappist_1d = @{
            Display     = 'TRAPPIST-1 d'
            DimensionId = -2102
            Region      = 'mid_systems'
            Signature   = 'stripped_mantle'
            Pending     = $true
            Card        = @(
                '0.39 Earth masses - the lightest body in the layer, and light enough that it could not'
                'hold its volatiles. What is left is bare mantle rock, which is what its signature vein is.'
            )
        }
        trappist_1e = @{
            Display     = 'TRAPPIST-1 e'
            DimensionId = -2103
            Region      = 'mid_systems'
            Signature   = 'dyson_wreck'
            # Not Pending any more: 6eh gave -2103 a provider that generates real ground and a GregTech stone type,
            # so the files below now have a world to generate in. The other eighty planned bodies stay Pending until
            # they get the same two things.
            Pending     = $false
            Card        = @(
                'The plan''s second sample body and the main stage for ruin type II: 250 K, probably a'
                'global ocean, and - per PLANET-CATALOG - the wreckage of a Dyson structure.'
                'That is where trinium and triniite come from: not minerals this planet made, but what'
                'is left of something built, which is the same honest route 6de named for ruin-delivered'
                'ore. Bowieite is the closest thing nature has, a rhodium-platinum sulphide.'
            )
        }
        trappist_1f = @{
            Display     = 'TRAPPIST-1 f'
            DimensionId = -2104
            Region      = 'mid_systems'
            Pending     = $true
            Card        = @(
                'An ice shell over an ocean that may be more than half the planet''s mass - Europa''s'
                'stack, at 40 light years, which is why its two veins are Europa''s rather than new ones.'
            )
        }
        trappist_1g = @{
            Display     = 'TRAPPIST-1 g'
            DimensionId = -2105
            Region      = 'mid_systems'
            Pending     = $true
            Card        = @(
                'Cold enough that the volatiles have already fractionated out: an ice world with an'
                'ice world''s crystal vein and nothing of its own.'
            )
        }
        trappist_1h = @{
            Display     = 'TRAPPIST-1 h'
            DimensionId = -2106
            Region      = 'mid_systems'
            Pending     = $true
            Card        = @(
                'The outermost of the chain, 0.33 Earth masses and 18.8 days: the resonance ends here,'
                'and so does anything interesting about its geology.'
            )
        }
        gliese_581c = @{
            Display     = 'Gliese 581 c'
            DimensionId = -2108
            Region      = 'mid_systems'
            Signature   = 'runaway_greenhouse'
            Pending     = $true
            Card        = @(
                'The first exoplanet ever announced as habitable, and then un-announced - the catalog'
                'keeps it as the textbook correction, and so does this card.'
                'Geologically it is the same story as TRAPPIST-1 c, which is why they share a vein:'
                'a greenhouse that never opened.'
            )
        }
        gliese_667c_c = @{
            Display     = 'Gliese 667 C c'
            DimensionId = -2111
            Region      = 'mid_systems'
            Pending     = $true
            Card        = @(
                'A stable orbit inside the habitable zone of a triple system - three suns in the sky,'
                'which is the reason this body is on the list rather than anything about its rock.'
                'No signature, and the card says so instead of inventing one.'
            )
        }
        hd_219134b = @{
            Display     = 'HD 219134 b'
            DimensionId = -2116
            Region      = 'mid_systems'
            Signature   = 'dense_siderophile'
            Pending     = $true
            Card        = @(
                'The catalog calls it the density benchmark for rocky exoplanets, and density is'
                'siderophile chemistry: the dense super-Earths are the ones whose iridium and osmium'
                'never left the metal phase.'
                'Which makes this the first body in the pack where those two are *mined* rather than'
                'recovered as a byproduct.'
            )
        }
        hd_40307g = @{
            Display     = 'HD 40307 g'
            DimensionId = -2121
            Region      = 'mid_systems'
            Signature   = 'temperate_brine'
            Pending     = $true
            Card        = @(
                '7.1 Earth masses at 255 K: the catalog calls it the mid-mass habitable-zone sample,'
                'and a body that size in that place has been wet long enough to make phosphates and'
                'evaporites - which is what its signature vein is.'
            )
        }
        cancri_55e = @{
            Display     = '55 Cancri e'
            DimensionId = -2119
            Region      = 'mid_systems'
            Signature   = 'magma_ocean'
            Pending     = $true
            Card        = @(
                '1958 K on the day side and a 0.74-day year: the catalog''s brief is "magma ocean mined'
                'directly", and that is what the signature is.'
                'A magma ocean is a separation plant - iron and titanium sink, the refractory sulphides'
                'stay, and arsenic is the one volatile that does not leave.'
            )
        }
    }

    Variants = @(

        @{
            Id      = 'mare_ilmenite'
            Name    = 'Mare_Ilmenite_Vein'
            Bodies  = @('moon')
            Weight  = 200
            Density = 0.25
            Min     = 5
            Max     = 40
            Radius  = @(14, 16)
            Rock    = 'ilmenite'
            Reason  = 'Mare basalt: up to 15 percent TiO2 as ilmenite, with the aluminium the same magma carried.'
            Ores    = @(
                @{ Ore = 'ilmenite';  Share = 55 }
                @{ Ore = 'aluminium'; Share = 25 }
                @{ Ore = 'bauxite';   Share = 15 }
                @{ Ore = 'iron';      Share = 5 }
            )
        }

        @{
            Id      = 'highland_anorthosite'
            Name    = 'Highland_Anorthosite_Vein'
            Bodies  = @('moon')
            Weight  = 180
            Density = 0.25
            Min     = 40
            Max     = 90
            Radius  = @(14, 16)
            Rock    = 'bauxite'
            Reason  = 'Highland anorthosite: the plagioclase crust that floated on the magma ocean - aluminium-rich and iron-poor.'
            Ores    = @(
                @{ Ore = 'bauxite';   Share = 55 }
                @{ Ore = 'aluminium'; Share = 25 }
                @{ Ore = 'ilmenite';  Share = 15 }
                @{ Ore = 'monazite';  Share = 5 }
            )
        }

        @{
            Id      = 'impact_iron_nickel'
            Name    = 'Impact_Iron_Nickel_Vein'
            Bodies  = @('moon')
            Weight  = 200
            Density = 0.25
            Min     = 5
            Max     = 60
            Radius  = @(16, 20)
            Rock    = 'iron'
            Reason  = 'Impact metal: iron-nickel from four billion years of impactors, mixed into the regolith - the Moon''s structural metal.'
            Ores    = @(
                @{ Ore = 'iron';       Share = 55 }
                @{ Ore = 'nickel';     Share = 25 }
                @{ Ore = 'cobaltite';  Share = 15 }
                @{ Ore = 'pentlandite'; Share = 5 }
            )
        }

        @{
            Id      = 'mare_sulfide'
            Name    = 'Mare_Sulfide_Vein'
            Bodies  = @('moon')
            Weight  = 90
            Density = 0.2
            Min     = 20
            Max     = 60
            Radius  = @(12, 14)
            Rock    = 'sulfur'
            Reason  = 'Sulphide melt that separated from the mare magma before it erupted, taking the volatile metals with it.'
            Ores    = @(
                @{ Ore = 'sulfur';   Share = 50 }
                @{ Ore = 'galena';   Share = 25 }
                @{ Ore = 'lead';     Share = 15 }
                @{ Ore = 'redstone'; Share = 10 }
            )
        }

        @{
            Id      = 'impact_platinum'
            Name    = 'Impact_Platinum_Vein'
            Bodies  = @('moon')
            Weight  = 25
            Density = 0.15
            Min     = 5
            Max     = 30
            Radius  = @(8, 12)
            Rock    = 'platinum'
            Reason  = 'Platinum-group metal from the same impactors, concentrated in the melt sheets at the floors of the great basins.'
            Ores    = @(
                @{ Ore = 'platinum';  Share = 40 }
                @{ Ore = 'palladium'; Share = 25 }
                @{ Ore = 'cooperite'; Share = 20 }
                @{ Ore = 'gold';      Share = 15 }
            )
        }

        @{
            Id      = 'kreep_rare_earth'
            Name    = 'KREEP_Rare_Earth_Vein'
            Bodies  = @('moon')
            Weight  = 20
            Density = 0.15
            Min     = 5
            Max     = 30
            Radius  = @(8, 12)
            Rock    = 'bastnasite'
            Reason  = 'KREEP - potassium, rare-earth elements and phosphorus: the incompatible residue of the magma ocean, and the Moon''s headline resource.'
            Ores    = @(
                @{ Ore = 'bastnasite'; Share = 50 }
                @{ Ore = 'monazite';   Share = 25 }
                @{ Ore = 'neodymium';  Share = 15 }
                @{ Ore = 'thorium';    Share = 10 }
            )
        }

        @{
            Id      = 'impact_diamond'
            Name    = 'Impact_Diamond_Vein'
            Bodies  = @('moon')
            Weight  = 12
            Density = 0.15
            Min     = 5
            Max     = 25
            Radius  = @(6, 8)
            Rock    = 'diamond'
            Reason  = 'Impact microdiamonds with the graphite and silica glass the same shock waves formed, as found in lunar meteorites.'
            Ores    = @(
                @{ Ore = 'diamond';  Share = 45 }
                @{ Ore = 'graphite'; Share = 35 }
                @{ Ore = 'quartzite'; Share = 20 }
            )
        }

        # --- the frontier suite: shared by the four nearby-system bodies ------------------------

        @{
            Id      = 'frontier_silicate'
            Name    = 'Frontier_Silicate_Vein'
            Bodies  = @('ceres', 'pluto', 'kuiper_belt', 'haumea', 'triton', 'miranda', 'callisto',
                        'enceladus', 'ganymede', 'titan', 'mercury')
            Weight  = 220
            Density = 0.25
            Min     = 5
            Max     = 60
            Radius  = @(14, 16)
            Rock    = 'bauxite'
            Reason  = 'Provisional: an old, cold silicate crust - the same aluminium-bearing rock every rocky body out there shows.'
            Ores    = @(
                @{ Ore = 'bauxite';   Share = 45 }
                @{ Ore = 'aluminium'; Share = 25 }
                @{ Ore = 'quartzite'; Share = 20 }
                @{ Ore = 'iron';      Share = 10 }
            )
        }

        @{
            Id      = 'frontier_iron_nickel'
            Name    = 'Frontier_Iron_Nickel_Vein'
            Bodies  = @('titan')
            Weight  = 200
            Density = 0.25
            Min     = 5
            Max     = 60
            Radius  = @(16, 20)
            Rock    = 'iron'
            Reason  = 'Provisional: metallic iron-nickel, the one ore every differentiated rocky body carries.'
            Ores    = @(
                @{ Ore = 'iron';        Share = 50 }
                @{ Ore = 'nickel';      Share = 25 }
                @{ Ore = 'cobaltite';   Share = 15 }
                @{ Ore = 'pentlandite'; Share = 10 }
            )
        }

        @{
            Id      = 'frontier_sulfide'
            Name    = 'Frontier_Sulfide_Vein'
            Weight  = 100
            Density = 0.2
            Min     = 5
            Max     = 50
            Radius  = @(12, 14)
            Rock    = 'sulfur'
            Reason  = 'Provisional: sulphide melt, the volatile half of the same differentiation.'
            Ores    = @(
                @{ Ore = 'sulfur';   Share = 45 }
                @{ Ore = 'galena';   Share = 25 }
                @{ Ore = 'lead';     Share = 20 }
                @{ Ore = 'redstone'; Share = 10 }
            )
        }

        @{
            Id      = 'frontier_rare_earth'
            Name    = 'Frontier_Rare_Earth_Vein'
            Bodies  = @('ceres', 'pluto', 'kuiper_belt', 'haumea', 'triton', 'miranda', 'callisto',
                        'enceladus', 'ganymede', 'io')
            Weight  = 25
            Density = 0.15
            Min     = 5
            Max     = 35
            Radius  = @(8, 12)
            Rock    = 'bastnasite'
            Reason  = 'Provisional: the incompatible-element residue of the same crust, and the reason to dig on a small body.'
            Ores    = @(
                @{ Ore = 'bastnasite'; Share = 45 }
                @{ Ore = 'monazite';   Share = 30 }
                @{ Ore = 'neodymium';  Share = 15 }
                @{ Ore = 'thorium';    Share = 10 }
            )
        }

        @{
            Id      = 'frontier_volatile'
            Name    = 'Frontier_Volatile_Vein'
            Bodies  = @('ceres', 'pluto', 'kuiper_belt', 'haumea', 'triton', 'miranda', 'callisto',
                        'enceladus', 'ganymede')
            Weight  = 60
            Density = 0.2
            Min     = 5
            Max     = 45
            Radius  = @(10, 14)
            Rock    = 'salt'
            Reason  = 'Provisional: evaporite brine - the only ore here that implies liquid water, which is why Proxima B is worth reaching.'
            Ores    = @(
                @{ Ore = 'salt';      Share = 40 }
                @{ Ore = 'rock_salt'; Share = 25 }
                @{ Ore = 'trona';     Share = 20 }
                @{ Ore = 'lithium';   Share = 15 }
            )
        }

        @{
            Id      = 'barnarda_onyx'
            Name    = '巴纳德缟玛瑙矿脉'
            Weight  = 120
            Density = 0.2
            Min     = 5
            Max     = 40
            Radius  = @(10, 14)
            Rock    = 'onyx'
            Reason  = '本整合包的原创材料，也是巴纳德星系的标志：缟玛瑙，与周围的方解石和硫共生。'
            Ores    = @(
                @{ Ore = 'onyx';    Share = 60 }
                @{ Ore = 'calcite'; Share = 25 }
                @{ Ore = 'sulfur';  Share = 15 }
            )
        }

        # --- Europa: the layered icy moon --------------------------------------------------------

        @{
            Id      = 'ice_shell_brine'
            Name    = 'Ice_Shell_Brine_Vein'
            Bodies  = @('europa', 'enceladus', 'trappist_1f')
            Folder  = 'europa'
            Weight  = 200
            Density = 0.25
            Min     = 5
            Max     = 45
            Radius  = @(14, 16)
            Rock    = 'salt'
            Reason  = 'Brine in the ice shell: the ocean''s salt, magnesium and lithium, left behind where the water froze.'
            Ores    = @(
                @{ Ore = 'salt';      Share = 40 }
                @{ Ore = 'rock_salt'; Share = 30 }
                @{ Ore = 'sulfur';    Share = 20 }
                @{ Ore = 'lithium';   Share = 10 }
            )
        }

        @{
            Id      = 'ice_shell_crystal'
            Name    = 'Ice_Shell_Crystal_Vein'
            Bodies  = @('europa', 'ceres', 'pluto', 'kuiper_belt', 'haumea', 'triton', 'miranda',
                        'callisto', 'ganymede', 'enceladus', 'titan',
                        'trappist_1f', 'trappist_1g', 'trappist_1h')
            Folder  = 'europa'
            Weight  = 150
            Density = 0.2
            Min     = 40
            Max     = 90
            Radius  = @(12, 14)
            Rock    = 'certus_quartz'
            Reason  = 'The crystalline part of the shell - clathrates and ice crystals, which this pack represents with its crystal minerals.'
            Ores    = @(
                @{ Ore = 'certus_quartz'; Share = 45 }
                @{ Ore = 'quartzite';     Share = 30 }
                @{ Ore = 'amethyst';      Share = 15 }
                @{ Ore = 'blue_topaz';    Share = 10 }
            )
        }

        @{
            Id      = 'tidal_hydrothermal'
            Name    = 'Tidal_Hydrothermal_Vein'
            Bodies  = @('europa')
            Weight  = 150
            Density = 0.2
            Min     = 5
            Max     = 50
            Radius  = @(12, 14)
            Rock    = 'sphalerite'
            Reason  = 'Ocean-floor hydrothermal sulphides: Jupiter''s tides are the heat source, so these are the vein that proves the ocean is still active.'
            Ores    = @(
                @{ Ore = 'sulfur';    Share = 40 }
                @{ Ore = 'galena';    Share = 25 }
                @{ Ore = 'sphalerite'; Share = 20 }
                @{ Ore = 'pyrite';    Share = 15 }
            )
        }

        @{
            Id      = 'silicate_mantle'
            Name    = 'Silicate_Mantle_Vein'
            Bodies  = @('europa', 'ganymede')
            Weight  = 180
            Density = 0.25
            Min     = 5
            Max     = 60
            Radius  = @(14, 16)
            Rock    = 'bauxite'
            Reason  = 'The rocky mantle under the ocean: ordinary silicate differentiation, aluminium first.'
            Ores    = @(
                @{ Ore = 'bauxite';   Share = 45 }
                @{ Ore = 'aluminium'; Share = 25 }
                @{ Ore = 'ilmenite';  Share = 20 }
                @{ Ore = 'iron';      Share = 10 }
            )
        }

        @{
            Id      = 'metallic_core'
            Name    = 'Metallic_Core_Vein'
            Bodies  = @('europa', 'ganymede')
            Weight  = 180
            Density = 0.25
            Min     = 5
            Max     = 60
            Radius  = @(16, 20)
            Rock    = 'iron'
            Reason  = 'The iron core at the bottom of the stack - the same metal every differentiated body has.'
            Ores    = @(
                @{ Ore = 'iron';        Share = 50 }
                @{ Ore = 'nickel';      Share = 30 }
                @{ Ore = 'cobaltite';   Share = 15 }
                @{ Ore = 'pentlandite'; Share = 5 }
            )
        }

        @{
            Id      = 'ocean_floor_pgm'
            Name    = 'Ocean_Floor_PGM_Vein'
            Bodies  = @('europa')
            Weight  = 20
            Density = 0.15
            Min     = 5
            Max     = 30
            Radius  = @(8, 12)
            Rock    = 'platinum'
            Reason  = 'Platinum-group metal concentrated where rock and water meet - scarce, deep, and the reason to keep digging under the ice.'
            Ores    = @(
                @{ Ore = 'platinum';  Share = 40 }
                @{ Ore = 'palladium'; Share = 25 }
                @{ Ore = 'cooperite'; Share = 20 }
                @{ Ore = 'gold';      Share = 15 }
            )
        }

        # --- Mars: the cold, rusted, once-wet world -----------------------------------------------

        @{
            Id      = 'martian_basalt'
            Name    = 'Martian_Basalt_Vein'
            Bodies  = @('mars')
            Weight  = 200
            Density = 0.25
            Min     = 5
            Max     = 60
            Radius  = @(14, 16)
            Rock    = 'iron'
            Reason  = 'Basaltic plains and shield volcanoes: iron-rich, titanium-bearing lava, the body of the crust.'
            Ores    = @(
                @{ Ore = 'iron';      Share = 45 }
                @{ Ore = 'magnetite'; Share = 25 }
                @{ Ore = 'ilmenite';  Share = 20 }
                @{ Ore = 'bauxite';   Share = 10 }
            )
        }

        @{
            Id      = 'martian_hematite'
            Name    = 'Martian_Hematite_Vein'
            Bodies  = @('mars')
            Weight  = 180
            Density = 0.25
            Min     = 5
            Max     = 60
            Radius  = @(14, 16)
            Rock    = 'magnetite'
            Reason  = 'The red planet''s oxidised iron: hematite and magnetite where the crust met its own lost air.'
            Ores    = @(
                @{ Ore = 'magnetite';   Share = 35 }
                @{ Ore = 'redstone';    Share = 30 }
                @{ Ore = 'iron';        Share = 20 }
                @{ Ore = 'banded_iron'; Share = 15 }
            )
        }

        @{
            Id      = 'martian_sulfate'
            Name    = 'Martian_Sulfate_Vein'
            Bodies  = @('mars')
            Weight  = 150
            Density = 0.2
            Min     = 5
            Max     = 60
            Radius  = @(12, 14)
            Rock    = 'gypsum'
            Reason  = 'Hydrated sulphates and clays - the water history, written where the northern ocean used to be.'
            Ores    = @(
                @{ Ore = 'gypsum';    Share = 40 }
                @{ Ore = 'bentonite'; Share = 25 }
                @{ Ore = 'sulfur';    Share = 20 }
                @{ Ore = 'kaolinite'; Share = 15 }
            )
        }

        @{
            Id      = 'martian_desh'
            Name    = '火星戴斯矿脉'
            Bodies  = @('mars')
            Weight  = 150
            Density = 0.25
            Min     = 5
            Max     = 50
            Radius  = @(12, 14)
            Rock    = 'desh'
            Reason  = '戴斯：本整合包的火星金属，保留为矿脉，因为 GC 的火星层级需要这种矿石，且没有其他来源。'
            Ores    = @(
                @{ Ore = 'desh';     Share = 55 }
                @{ Ore = 'nickel';   Share = 25 }
                @{ Ore = 'cobaltite'; Share = 20 }
            )
        }

        @{
            Id      = 'martian_evaporite'
            Name    = 'Martian_Evaporite_Vein'
            Bodies  = @('mars')
            Weight  = 100
            Density = 0.2
            Min     = 5
            Max     = 50
            Radius  = @(10, 14)
            Rock    = 'salt'
            Reason  = 'Evaporites: what the ocean left when it froze out and sublimed, concentrated in the low basins.'
            Ores    = @(
                @{ Ore = 'salt';      Share = 40 }
                @{ Ore = 'rock_salt'; Share = 30 }
                @{ Ore = 'niter';     Share = 20 }
                @{ Ore = 'lithium';   Share = 10 }
            )
        }

        @{
            Id      = 'martian_tungstate'
            Name    = 'Martian_Tungstate_Vein'
            Bodies  = @('mars')
            Weight  = 20
            Density = 0.15
            Min     = 5
            Max     = 40
            Radius  = @(8, 12)
            Rock    = 'scheelite'
            Reason  = 'Tungsten, scavenged by the same late magmas that built Tharsis - scarce, and the reason tungsten is reachable inside the solar system.'
            Ores    = @(
                @{ Ore = 'scheelite';  Share = 40 }
                @{ Ore = 'tungstate';  Share = 25 }
                @{ Ore = 'molybdenum'; Share = 20 }
                @{ Ore = 'powellite';  Share = 15 }
            )
        }

        @{
            Id      = 'martian_incompatible'
            Name    = 'Martian_Incompatible_Vein'
            Bodies  = @('mars')
            Weight  = 20
            Density = 0.15
            Min     = 5
            Max     = 35
            Radius  = @(8, 12)
            Rock    = 'pitchblende'
            Reason  = 'The incompatible elements the crust could not fit into its own minerals - uranium, thorium and the rare earths that travel with them.'
            Ores    = @(
                @{ Ore = 'pitchblende'; Share = 40 }
                @{ Ore = 'uraninite';   Share = 25 }
                @{ Ore = 'thorium';     Share = 20 }
                @{ Ore = 'neodymium';   Share = 15 }
            )
        }

        # --- Venus (and Galaxy Space's Venus, which is the same body) ------------------------------

        @{
            Id      = 'venusian_sulfide'
            Name    = 'Venusian_Sulfide_Vein'
            Bodies  = @('venus', 'gs_venus')
            Weight  = 200
            Density = 0.25
            Min     = 5
            Max     = 40
            Radius  = @(14, 16)
            Rock    = 'sulfur'
            Reason  = 'Primary high-temperature sulphides: a surface so hot that lead and sulphur separate instead of staying locked in rock.'
            Ores    = @(
                @{ Ore = 'sulfur';      Share = 40 }
                @{ Ore = 'galena';      Share = 25 }
                @{ Ore = 'tetrahedrite'; Share = 20 }
                @{ Ore = 'pyrite';      Share = 15 }
            )
        }

        @{
            Id      = 'venusian_basalt'
            Name    = 'Venusian_Basalt_Vein'
            Bodies  = @('venus', 'gs_venus')
            Weight  = 180
            Density = 0.25
            Min     = 5
            Max     = 60
            Radius  = @(14, 16)
            Rock    = 'iron'
            Reason  = 'The resurfaced basaltic plains: nothing on this body is older than the last eruption, so this is the crust itself.'
            Ores    = @(
                @{ Ore = 'iron';      Share = 40 }
                @{ Ore = 'ilmenite';  Share = 25 }
                @{ Ore = 'magnetite'; Share = 20 }
                @{ Ore = 'bauxite';   Share = 15 }
            )
        }

        @{
            Id      = 'venusian_acid_cloud'
            Name    = 'Venusian_Acid_Cloud_Vein'
            Bodies  = @('venus', 'gs_venus')
            Weight  = 120
            Density = 0.2
            Min     = 40
            Max     = 90
            Radius  = @(12, 14)
            Rock    = 'barite'
            Reason  = 'The cloud deck - the one ore in the system that forms in the sky, condensed out of sulphuric acid forty to ninety blocks up.'
            Ores    = @(
                @{ Ore = 'sulfur';    Share = 45 }
                @{ Ore = 'barite';    Share = 25 }
                @{ Ore = 'niter';     Share = 20 }
                @{ Ore = 'rock_salt'; Share = 10 }
            )
        }

        @{
            Id      = 'venusian_evaporite'
            Name    = 'Venusian_Evaporite_Vein'
            Bodies  = @('venus', 'gs_venus')
            Weight  = 100
            Density = 0.2
            Min     = 5
            Max     = 50
            Radius  = @(10, 14)
            Rock    = 'rock_salt'
            Reason  = 'Evaporites of the oceans Venus used to have, cooked dry and buried under the lava that replaced them.'
            Ores    = @(
                @{ Ore = 'rock_salt'; Share = 40 }
                @{ Ore = 'salt';      Share = 30 }
                @{ Ore = 'trona';     Share = 20 }
                @{ Ore = 'gypsum';    Share = 10 }
            )
        }

        @{
            Id      = 'venusian_gem'
            Name    = 'Venusian_Gem_Vein'
            Bodies  = @('venus', 'gs_venus')
            Weight  = 60
            Density = 0.2
            Min     = 20
            Max     = 60
            Radius  = @(10, 14)
            Rock    = 'sapphire'
            Reason  = 'Corundum: ninety times Earth''s pressure makes ruby and sapphire out of the same aluminium the basalt carries.'
            Ores    = @(
                @{ Ore = 'sapphire';      Share = 30 }
                @{ Ore = 'ruby';          Share = 25 }
                @{ Ore = 'green_sapphire'; Share = 25 }
                @{ Ore = 'cassiterite';   Share = 20 }
            )
        }

        @{
            Id      = 'venusian_cinnabar'
            Name    = 'Venusian_Cinnabar_Vein'
            Bodies  = @('venus', 'gs_venus')
            Weight  = 25
            Density = 0.15
            Min     = 5
            Max     = 35
            Radius  = @(8, 12)
            Rock    = 'cinnabar'
            Reason  = 'Volatile metals that only stay put this close to a hot surface: mercury as cinnabar, with the tellurium that travels with it.'
            Ores    = @(
                @{ Ore = 'cinnabar';  Share = 40 }
                @{ Ore = 'tellurium'; Share = 30 }
                @{ Ore = 'redstone';  Share = 20 }
                @{ Ore = 'silver';    Share = 10 }
            )
        }

        @{
            Id      = 'venusian_solar'
            Name    = '金星太阳石矿脉'
            Bodies  = @('venus', 'gs_venus')
            Weight  = 40
            Density = 0.15
            Min     = 5
            Max     = 40
            Radius  = @(8, 12)
            Rock    = 'solar'
            Reason  = '太阳石：本整合包为最靠近太阳的天体设计的材料，与偏好高温还原熔体的银和碲共生。'
            Ores    = @(
                @{ Ore = 'solar';     Share = 55 }
                @{ Ore = 'silver';    Share = 25 }
                @{ Ore = 'tellurium'; Share = 20 }
            )
        }

        # --- the belt: planetesimals that never sorted themselves ----------------------------------

        @{
            Id      = 'asteroid_metal'
            Name    = 'Asteroid_Metal_Vein'
            Bodies  = @('asteroids', 'phobos', 'deimos')
            Weight  = 200
            Density = 0.25
            Min     = 5
            Max     = 60
            Radius  = @(16, 20)
            Rock    = 'iron'
            Reason  = 'M-type planetesimals: metal that never sank into a core because the body never had one.'
            Ores    = @(
                @{ Ore = 'meteoric_iron'; Share = 40 }
                @{ Ore = 'iron';          Share = 30 }
                @{ Ore = 'nickel';        Share = 20 }
                @{ Ore = 'cobaltite';     Share = 10 }
            )
        }

        @{
            Id      = 'asteroid_silicate'
            Name    = 'Asteroid_Silicate_Vein'
            Bodies  = @('asteroids', 'phobos', 'deimos')
            Weight  = 180
            Density = 0.25
            Min     = 5
            Max     = 60
            Radius  = @(14, 16)
            Rock    = 'bauxite'
            Reason  = 'S-type planetesimals: ordinary chondritic rock, aluminium first, exactly as it condensed.'
            Ores    = @(
                @{ Ore = 'bauxite';   Share = 40 }
                @{ Ore = 'quartzite'; Share = 30 }
                @{ Ore = 'aluminium'; Share = 20 }
                @{ Ore = 'iron';      Share = 10 }
            )
        }

        @{
            Id      = 'asteroid_carbonaceous'
            Name    = 'Asteroid_Carbonaceous_Vein'
            Bodies  = @('asteroids', 'phobos', 'deimos', 'ceres', 'pluto', 'kuiper_belt', 'haumea',
                        'triton', 'miranda', 'callisto')
            Weight  = 120
            Density = 0.2
            Min     = 5
            Max     = 60
            Radius  = @(12, 14)
            Rock    = 'graphite'
            Reason  = 'C-type planetesimals: the most primitive material in the system - carbon, sulphur and organics that were never cooked.'
            Ores    = @(
                @{ Ore = 'graphite'; Share = 35 }
                @{ Ore = 'coal';     Share = 25 }
                @{ Ore = 'sulfur';   Share = 25 }
                @{ Ore = 'diamond';  Share = 15 }
            )
        }

        @{
            Id      = 'asteroid_pgm'
            Name    = 'Asteroid_PGM_Vein'
            Bodies  = @('asteroids', 'phobos', 'deimos')
            Weight  = 40
            Density = 0.15
            Min     = 5
            Max     = 40
            Radius  = @(8, 12)
            Rock    = 'platinum'
            Reason  = 'The platinum group concentrated in metallic planetesimals - the belt''s headline resource and the reason to go out there.'
            Ores    = @(
                @{ Ore = 'platinum';  Share = 35 }
                @{ Ore = 'palladium'; Share = 30 }
                @{ Ore = 'cooperite'; Share = 20 }
                @{ Ore = 'gold';      Share = 15 }
            )
        }

        @{
            Id      = 'asteroid_diamond'
            Name    = 'Asteroid_Diamond_Vein'
            Bodies  = @('asteroids')
            Weight  = 20
            Density = 0.15
            Min     = 5
            Max     = 35
            Radius  = @(6, 8)
            Rock    = 'diamond'
            Reason  = 'Primordial and impact diamond with the graphite and silica of the same primitive material.'
            Ores    = @(
                @{ Ore = 'diamond';  Share = 40 }
                @{ Ore = 'graphite'; Share = 35 }
                @{ Ore = 'amethyst'; Share = 25 }
            )
        }

        @{
            Id      = 'asteroid_tungstate'
            Name    = 'Asteroid_Tungstate_Vein'
            Bodies  = @('asteroids', 'phobos', 'deimos')
            Weight  = 16
            Density = 0.15
            Min     = 5
            Max     = 40
            Radius  = @(8, 12)
            Rock    = 'scheelite'
            Reason  = 'Tungsten in the same primitive material - the second place it can be had without leaving the solar system.'
            Ores    = @(
                @{ Ore = 'scheelite'; Share = 45 }
                @{ Ore = 'tungstate'; Share = 35 }
                @{ Ore = 'powellite'; Share = 20 }
            )
        }

        @{
            Id      = 'asteroid_naquadah'
            Name    = 'Asteroid_Naquadah_Vein'
            Bodies  = @('asteroids')
            Weight  = 12
            Density = 0.15
            Min     = 5
            Max     = 40
            Radius  = @(6, 8)
            Rock    = 'naquadah'
            Reason  = 'Naquadah: a material this pack treats as deep-space, so the belt is where it first shows up - scarce, and the belt''s other reason to be visited.'
            Ores    = @(
                @{ Ore = 'naquadah';                    Share = 55 }
                @{ Ore = 'naquadric_compound';          Share = 25 }
                @{ Ore = 'enriched_naquadric_compound'; Share = 20 }
            )
        }

        # --- the icy dwarf planets and Kuiper Belt objects: one signature each, the rest shared ----

        @{
            Id      = 'ceres_carbonate'
            Name    = 'Ceres_Carbonate_Vein'
            Bodies  = @('ceres')
            Weight  = 150
            Density = 0.2
            Min     = 5
            Max     = 45
            Radius  = @(12, 14)
            Rock    = 'dolomite'
            Reason  = 'Carbonates left by Ceres'' briny subsurface water - the one body in the belt with a water history, and this pack''s own dolomite.'
            Ores    = @(
                @{ Ore = 'dolomite'; Share = 45 }
                @{ Ore = 'calcite';  Share = 30 }
                @{ Ore = 'gypsum';   Share = 25 }
            )
        }

        @{
            Id      = 'pluto_tholin'
            Name    = 'Pluto_Tholin_Vein'
            Bodies  = @('pluto')
            Weight  = 120
            Density = 0.2
            Min     = 5
            Max     = 45
            Radius  = @(12, 14)
            Rock    = 'graphite'
            Reason  = 'Tholins: the reddish organic haze sunlight makes out of methane - not life, just chemistry, and Pluto''s colour.'
            Ores    = @(
                @{ Ore = 'graphite'; Share = 45 }
                @{ Ore = 'coal';     Share = 30 }
                @{ Ore = 'sulfur';   Share = 25 }
            )
        }

        @{
            Id      = 'kuiper_exotic'
            Name    = 'Kuiper_Exotic_Vein'
            Bodies  = @('kuiper_belt')
            Weight  = 10
            Density = 0.15
            Min     = 5
            Max     = 40
            Radius  = @(6, 8)
            Rock    = 'naquadah'
            Reason  = 'Naquadah where the sun is weak enough for it: the far edge is the second and last place this pack puts it.'
            Ores    = @(
                @{ Ore = 'naquadah';                    Share = 50 }
                @{ Ore = 'naquadric_compound';          Share = 30 }
                @{ Ore = 'enriched_naquadric_compound'; Share = 20 }
            )
        }

        # --- Mercury: iron core with a thin shell, and no air to rust it ---------------------------

        @{
            Id      = 'mercurian_core_metal'
            Name    = 'Mercurian_Core_Metal_Vein'
            Bodies  = @('mercury')
            Weight  = 220
            Density = 0.25
            Min     = 5
            Max     = 60
            Radius  = @(16, 20)
            Rock    = 'iron'
            Reason  = 'The core is most of the planet, and the crust is impact debris off it - unoxidised metal, which nothing else this close to the sun can be.'
            Ores    = @(
                @{ Ore = 'iron';        Share = 45 }
                @{ Ore = 'nickel';      Share = 30 }
                @{ Ore = 'cobaltite';   Share = 15 }
                @{ Ore = 'pentlandite'; Share = 10 }
            )
        }

        @{
            Id      = 'mercurian_silicate'
            Name    = 'Mercurian_Silicate_Vein'
            Bodies  = @('mercury')
            Weight  = 160
            Density = 0.25
            Min     = 5
            Max     = 60
            Radius  = @(14, 16)
            Rock    = 'bauxite'
            Reason  = 'The thin silicate shell over that core: ordinary rock, in unusually small amounts.'
            Ores    = @(
                @{ Ore = 'bauxite';   Share = 45 }
                @{ Ore = 'aluminium'; Share = 25 }
                @{ Ore = 'ilmenite';  Share = 20 }
                @{ Ore = 'iron';      Share = 10 }
            )
        }

        @{
            Id      = 'mercurian_sulfide'
            Name    = 'Mercurian_Sulfide_Vein'
            Bodies  = @('mercury')
            Weight  = 140
            Density = 0.2
            Min     = 5
            Max     = 50
            Radius  = @(12, 14)
            Rock    = 'sulfur'
            Reason  = 'Mercury turns out to be rich in sulphur for a body that formed this close to the sun - enough of it to make primary sulphides worth mining.'
            Ores    = @(
                @{ Ore = 'sulfur'; Share = 45 }
                @{ Ore = 'galena'; Share = 25 }
                @{ Ore = 'pyrite'; Share = 20 }
                @{ Ore = 'lead';   Share = 10 }
            )
        }

        @{
            Id      = 'mercurian_graphite'
            Name    = 'Mercurian_Graphite_Vein'
            Bodies  = @('mercury')
            Weight  = 60
            Density = 0.2
            Min     = 5
            Max     = 40
            Radius  = @(10, 14)
            Rock    = 'graphite'
            Reason  = 'The dark material that makes Mercury''s surface so low-reflectance: carbon, left as graphite by the same impacts.'
            Ores    = @(
                @{ Ore = 'graphite'; Share = 45 }
                @{ Ore = 'coal';     Share = 30 }
                @{ Ore = 'diamond';  Share = 25 }
            )
        }

        @{
            Id      = 'mercurian_pgm'
            Name    = 'Mercurian_PGM_Vein'
            Bodies  = @('mercury')
            Weight  = 30
            Density = 0.15
            Min     = 5
            Max     = 35
            Radius  = @(8, 12)
            Rock    = 'platinum'
            Reason  = 'Impact-delivered platinum-group metal, concentrated the way the Moon''s is - the second source before the belt is reachable.'
            Ores    = @(
                @{ Ore = 'platinum';  Share = 35 }
                @{ Ore = 'palladium'; Share = 30 }
                @{ Ore = 'cooperite'; Share = 20 }
                @{ Ore = 'gold';      Share = 15 }
            )
        }

        # --- Io: everything volcanic, nothing volatile --------------------------------------------

        @{
            Id      = 'io_sulfur'
            Name    = 'Io_Sulfur_Vein'
            Bodies  = @('io')
            Weight  = 220
            Density = 0.25
            Min     = 5
            Max     = 50
            Radius  = @(14, 16)
            Rock    = 'sulfur'
            Reason  = 'Io is painted in sulphur because that is what its volcanoes put out, tonnes of it a second.'
            Ores    = @(
                @{ Ore = 'sulfur'; Share = 50 }
                @{ Ore = 'pyrite'; Share = 25 }
                @{ Ore = 'galena'; Share = 15 }
                @{ Ore = 'lead';   Share = 10 }
            )
        }

        @{
            Id      = 'io_volcanic_silicate'
            Name    = 'Io_Volcanic_Silicate_Vein'
            Bodies  = @('io')
            Weight  = 180
            Density = 0.25
            Min     = 5
            Max     = 60
            Radius  = @(14, 16)
            Rock    = 'iron'
            Reason  = 'The ultramafic lava the sulphur comes out of: iron and titanium rich, and hot enough that nothing survives on the surface.'
            Ores    = @(
                @{ Ore = 'olivine';  Share = 40 }
                @{ Ore = 'iron';     Share = 30 }
                @{ Ore = 'ilmenite'; Share = 30 }
            )
        }

        @{
            Id      = 'io_sulfide'
            Name    = 'Io_Sulfide_Vein'
            Bodies  = @('io')
            Weight  = 140
            Density = 0.2
            Min     = 5
            Max     = 50
            Radius  = @(12, 14)
            Rock    = 'pyrite'
            Reason  = 'The other half of the volcanic output: the base-metal sulphides that separate out of the same melt.'
            Ores    = @(
                @{ Ore = 'pyrite';       Share = 40 }
                @{ Ore = 'chalcopyrite'; Share = 30 }
                @{ Ore = 'galena';       Share = 20 }
                @{ Ore = 'sphalerite';   Share = 10 }
            )
        }

        @{
            Id      = 'io_alkali_salt'
            Name    = 'Io_Alkali_Salt_Vein'
            Bodies  = @('io')
            Weight  = 100
            Density = 0.2
            Min     = 5
            Max     = 45
            Radius  = @(10, 14)
            Rock    = 'rock_salt'
            Reason  = 'The plumes are alkali-rich - sodium and potassium, in a ring all the way around Jupiter - and this is where they land.'
            Ores    = @(
                @{ Ore = 'rock_salt'; Share = 45 }
                @{ Ore = 'salt';      Share = 30 }
                @{ Ore = 'trona';     Share = 25 }
            )
        }

        @{
            Id      = 'io_pgm'
            Name    = 'Io_PGM_Vein'
            Bodies  = @('io')
            Weight  = 20
            Density = 0.15
            Min     = 5
            Max     = 30
            Radius  = @(8, 12)
            Rock    = 'platinum'
            Reason  = 'Platinum-group metal brought up with the deep magma - scarce, and Io''s only answer to the belt.'
            Ores    = @(
                @{ Ore = 'platinum';  Share = 35 }
                @{ Ore = 'palladium'; Share = 25 }
                @{ Ore = 'cooperite'; Share = 20 }
                @{ Ore = 'gold';      Share = 20 }
            )
        }

        # --- Titan: hydrocarbon and nitrogen chemistry, and ice underneath -------------------------

        @{
            Id      = 'titan_hydrocarbon'
            Name    = 'Titan_Hydrocarbon_Vein'
            Bodies  = @('titan')
            Weight  = 220
            Density = 0.25
            Min     = 5
            Max     = 40
            Radius  = @(14, 16)
            Rock    = 'oilsands'
            Reason  = 'Lakes and dunes of methane and ethane: the only body besides Earth with liquid on the surface, and it is hydrocarbons.'
            Ores    = @(
                @{ Ore = 'oilsands'; Share = 45 }
                @{ Ore = 'coal';     Share = 30 }
                @{ Ore = 'graphite'; Share = 25 }
            )
        }

        @{
            Id      = 'titan_nitrogen'
            Name    = 'Titan_Nitrogen_Vein'
            Bodies  = @('titan')
            Weight  = 150
            Density = 0.2
            Min     = 40
            Max     = 90
            Radius  = @(12, 14)
            Rock    = 'niter'
            Reason  = 'The nitrogen haze itself, forty to ninety blocks up - niter stands in for it, because this pack has no nitrogen ore.'
            Ores    = @(
                @{ Ore = 'niter';     Share = 45 }
                @{ Ore = 'rock_salt'; Share = 30 }
                @{ Ore = 'trona';     Share = 25 }
            )
        }

        # --- the nearby systems: five real cards, and ten of the closure gaps filled ---------------

        @{
            Id      = 'flare_baked_regolith'
            Name    = 'Flare_Baked_Regolith_Vein'
            Bodies  = @('proxima_b')
            Weight  = 150
            Density = 0.2
            Min     = 5
            Max     = 45
            Radius  = @(10, 14)
            Rock    = 'sulfur'
            Reason  = 'Proxima is a flare star: the day side is baked by X-rays every few hours, so the surface is sulphur- and nitrate-rich rather than weathered.'
            Ores    = @(
                @{ Ore = 'sulfur';    Share = 40 }
                @{ Ore = 'niter';     Share = 25 }
                @{ Ore = 'redstone';  Share = 25 }
                @{ Ore = 'tellurium'; Share = 10 }
            )
        }

        @{
            Id      = 'substellar_sea'
            Name    = 'Substellar_Sea_Vein'
            Bodies  = @('proxima_b')
            Weight  = 200
            Density = 0.25
            Min     = 5
            Max     = 45
            Radius  = @(12, 14)
            Rock    = 'salt'
            Reason  = 'The only liquid water on the planet is the substellar sea on the day side, and this is what it left behind.'
            Ores    = @(
                @{ Ore = 'salt';    Share = 40 }
                @{ Ore = 'lithium'; Share = 30 }
                @{ Ore = 'calcite'; Share = 30 }
            )
        }

        @{
            Id      = 'proxima_zircon'
            Name    = 'Proxima_Zircon_Vein'
            Bodies  = @('proxima_b')
            Weight  = 20
            Density = 0.15
            Min     = 5
            Max     = 35
            Radius  = @(8, 12)
            Rock    = 'zircon'
            Reason  = 'The oldest, most repeatedly re-melted crust in the pack: zircon and its niobium-rare-earth companions survive melting and cooling where everything else does not.'
            Ores    = @(
                @{ Ore = 'zircon';     Share = 45 }
                @{ Ore = 'pyrochlore'; Share = 30 }
                @{ Ore = 'monazite';   Share = 25 }
            )
        }

        @{
            Id      = 'barnarda_basalt'
            Name    = 'Barnarda_Basalt_Vein'
            Bodies  = @('barnarda_c', 'barnarda_c1', 'barnarda_c2')
            Weight  = 180
            Density = 0.25
            Min     = 5
            Max     = 60
            Radius  = @(14, 16)
            Rock    = 'iron'
            Reason  = 'The ordinary crust of all three bodies: basalt that has not been disturbed in billions of years.'
            Ores    = @(
                @{ Ore = 'iron';      Share = 40 }
                @{ Ore = 'magnetite'; Share = 25 }
                @{ Ore = 'ilmenite';  Share = 20 }
                @{ Ore = 'bauxite';   Share = 15 }
            )
        }

        @{
            Id      = 'barnarda_deep_crystal'
            Name    = 'Barnarda_Deep_Crystal_Vein'
            Bodies  = @('barnarda_c', 'barnarda_c1', 'barnarda_c2')
            Weight  = 120
            Density = 0.2
            Min     = 20
            Max     = 70
            Radius  = @(10, 14)
            Rock    = 'quartzite'
            Reason  = 'A cold, old, water-bearing crust grows crystals slowly and keeps them; this is the system''s mineral collection.'
            Ores    = @(
                @{ Ore = 'quartzite';  Share = 40 }
                @{ Ore = 'amethyst';   Share = 25 }
                @{ Ore = 'blue_topaz'; Share = 20 }
                @{ Ore = 'topaz';      Share = 15 }
            )
        }

        @{
            Id      = 'barnarda_pegmatite'
            Name    = 'Barnarda_Pegmatite_Vein'
            Bodies  = @('barnarda_c1')
            Weight  = 25
            Density = 0.15
            Min     = 5
            Max     = 40
            Radius  = @(8, 12)
            Rock    = 'columbite'
            Reason  = 'The last, water-rich liquid of a small body''s magma: niobium, tantalum and gallium concentrate there and nowhere else - a pegmatite is what a planet''s leftovers make.'
            Ores    = @(
                @{ Ore = 'columbite';  Share = 40 }
                @{ Ore = 'gallite';    Share = 30 }
                @{ Ore = 'cassiterite'; Share = 30 }
            )
        }

        @{
            Id      = 'barnarda_ruin_cache'
            Name    = 'Barnarda_Ruin_Cache_Vein'
            Bodies  = @('barnarda_c2')
            Weight  = 30
            Density = 0.15
            Min     = 5
            Max     = 40
            Radius  = @(8, 12)
            Rock    = 'opal'
            Reason  = 'Not geology: vinteum, opal and jasper in a cache on a world that could not have made them, which is the honest way to place an ore whose origin is artificial.'
            Ores    = @(
                @{ Ore = 'vinteum'; Share = 40 }
                @{ Ore = 'opal';    Share = 30 }
                @{ Ore = 'jasper';  Share = 30 }
            )
        }

        @{
            Id      = 'tauceti_pressure_diamond'
            Name    = 'TauCeti_Pressure_Diamond_Vein'
            Bodies  = @('tauceti_f')
            Weight  = 90
            Density = 0.2
            Min     = 5
            Max     = 60
            Radius  = @(12, 14)
            Rock    = 'diamond'
            Reason  = 'A super-Earth is deep enough that diamond is a rock-forming mineral rather than a gem, and the carbon comes up with the same magmas as the magnesite.'
            Ores    = @(
                @{ Ore = 'diamond';   Share = 40 }
                @{ Ore = 'graphite';  Share = 30 }
                @{ Ore = 'magnesite'; Share = 30 }
            )
        }

        @{
            Id      = 'tauceti_carbonate'
            Name    = 'TauCeti_Carbonate_Vein'
            Bodies  = @('tauceti_f')
            Weight  = 25
            Density = 0.15
            Min     = 5
            Max     = 45
            Radius  = @(8, 12)
            Rock    = 'witherite'
            Reason  = 'An old, metal-poor star and a planet wet enough to have made carbonates and sulphates over billions of years: witherite, celestine and rhodocrosite are what that crust accumulates.'
            Ores    = @(
                @{ Ore = 'witherite';   Share = 35 }
                @{ Ore = 'celestine';   Share = 35 }
                @{ Ore = 'rhodocrosite'; Share = 30 }
            )
        }

        # --- layer 3, the mid systems: the layer delta, and five signatures -------------------------

        @{
            Id      = 'heavy_refractory'
            Name    = 'Heavy_Refractory_Vein'
            Weight  = 120
            Density = 0.2
            Min     = 5
            Max     = 55
            Radius  = @(10, 14)
            Rock    = 'scheelite'
            Reason  = 'The layer delta: refractory sulphides and oxides, the fraction that survives a hot, active crust and is worth the trip out here.'
            Ores    = @(
                @{ Ore = 'scheelite';   Share = 30 }
                @{ Ore = 'molybdenite'; Share = 25 }
                @{ Ore = 'molybdenum';  Share = 25 }
                @{ Ore = 'powellite';   Share = 20 }
            )
        }

        @{
            Id      = 'dyson_wreck'
            Name    = 'Dyson_Wreck_Vein'
            Bodies  = @('trappist_1e')
            Weight  = 25
            Density = 0.15
            Min     = 5
            Max     = 40
            Radius  = @(8, 12)
            Rock    = 'trinium'
            Reason  = 'Wreckage of a type II structure: trinium and triniite are not minerals a planet makes, and bowieite is the closest thing nature has to them - a rhodium-platinum sulphide.'
            Ores    = @(
                @{ Ore = 'trinium';   Share = 45 }
                @{ Ore = 'triniite';  Share = 35 }
                @{ Ore = 'bowieite';  Share = 20 }
            )
        }

        @{
            Id      = 'magma_ocean'
            Name    = 'Magma_Ocean_Vein'
            Bodies  = @('cancri_55e')
            Weight  = 90
            Density = 0.25
            Min     = 5
            Max     = 45
            Radius  = @(12, 14)
            Rock    = 'magnetite'
            Reason  = 'A magma ocean is a separation plant: iron and titanium sink, the refractory sulphides stay behind, and arsenic is the one volatile that does not boil off.'
            Ores    = @(
                @{ Ore = 'magnetite';   Share = 30 }
                @{ Ore = 'ilmenite';    Share = 25 }
                @{ Ore = 'arsenopyrite'; Share = 25 }
                @{ Ore = 'rutile';      Share = 20 }
            )
        }

        @{
            Id      = 'runaway_greenhouse'
            Name    = 'Runaway_Greenhouse_Vein'
            Bodies  = @('trappist_1c', 'gliese_581c')
            Weight  = 100
            Density = 0.2
            Min     = 5
            Max     = 45
            Radius  = @(10, 14)
            Rock    = 'barite'
            Reason  = 'Two planets that were announced as habitable and are not: the sulphur, salt and sulphate that a greenhouse leaves when the water is gone.'
            Ores    = @(
                @{ Ore = 'sulfur';    Share = 40 }
                @{ Ore = 'barite';    Share = 25 }
                @{ Ore = 'niter';     Share = 20 }
                @{ Ore = 'rock_salt'; Share = 15 }
            )
        }

        @{
            Id      = 'stripped_mantle'
            Name    = 'Stripped_Mantle_Vein'
            Bodies  = @('trappist_1d')
            Weight  = 140
            Density = 0.25
            Min     = 5
            Max     = 55
            Radius  = @(12, 14)
            Rock    = 'olivine'
            Reason  = 'Too light to hold an atmosphere and too small to keep a crust: what is left is mantle rock, and mantle rock is olivine, magnesite and chromite.'
            Ores    = @(
                @{ Ore = 'olivine';   Share = 40 }
                @{ Ore = 'magnesite'; Share = 30 }
                @{ Ore = 'chromite';  Share = 30 }
            )
        }

        @{
            Id      = 'dense_siderophile'
            Name    = 'Dense_Siderophile_Vein'
            Bodies  = @('hd_219134b')
            Weight  = 25
            Density = 0.15
            Min     = 5
            Max     = 40
            Radius  = @(8, 12)
            Rock    = 'iridium'
            Reason  = 'A dense super-Earth is dense because its siderophiles never left the metal phase: iridium and osmium at the top of the core, which is the first place in the pack they are mined rather than recovered.'
            Ores    = @(
                @{ Ore = 'iridium';  Share = 40 }
                @{ Ore = 'osmium';   Share = 35 }
                @{ Ore = 'platinum'; Share = 25 }
            )
        }

        @{
            Id      = 'temperate_brine'
            Name    = 'Temperate_Brine_Vein'
            Bodies  = @('hd_40307g')
            Weight  = 40
            Density = 0.2
            Min     = 5
            Max     = 50
            Radius  = @(10, 14)
            Rock    = 'fluoroapatite'
            Reason  = 'Wet for billions of years at 255 K: a crust that keeps making and drying out brine accumulates phosphates and evaporites, and those are exactly what is left.'
            Ores    = @(
                @{ Ore = 'fluoroapatite'; Share = 40 }
                @{ Ore = 'caliche';       Share = 30 }
                @{ Ore = 'barytocalcite'; Share = 30 }
            )
        }

    )
}
