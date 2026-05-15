-- Migration 0004 — seed data for the astro_* deterministic reference tables.
-- Idempotent: every INSERT uses ON CONFLICT … DO UPDATE so the file is
-- safe to re-run. Voice: modern, grounded, no mystical jargon, no
-- malefic/benefic framing — per master_doc §1 product context.

-- Expected row counts after this seed (handoff §4.2):
--   planets=10, points=8, signs=12, houses=12, aspects=11, dignities=47,
--   decans=36, lunar_phases=8, elements=4, modalities=3, house_systems=4,
--   synastry_patterns=14, moon_compatibility=16, transit_significance=10,
--   app_settings=13, overridable_preferences=7

-- ============================================================================
-- ELEMENTS (4)
-- ============================================================================
INSERT INTO public.astro_elements (id, name, archetype, modern_keywords, compatible_elements, challenging_elements) VALUES
('fire',  'Fire',  'spark and momentum',
    ARRAY['initiative','warmth','presence','enthusiasm','will','direct action'],
    ARRAY['fire','air'], ARRAY['water','earth']),
('earth', 'Earth', 'groundedness and material',
    ARRAY['steadiness','build','body','resources','practical','rhythm'],
    ARRAY['earth','water'], ARRAY['fire','air']),
('air',   'Air',   'thought and exchange',
    ARRAY['ideas','language','connection','curiosity','perspective','networks'],
    ARRAY['air','fire'], ARRAY['earth','water']),
('water', 'Water', 'feeling and depth',
    ARRAY['emotion','intuition','memory','empathy','intimacy','undercurrents'],
    ARRAY['water','earth'], ARRAY['fire','air'])
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    archetype = EXCLUDED.archetype,
    modern_keywords = EXCLUDED.modern_keywords,
    compatible_elements = EXCLUDED.compatible_elements,
    challenging_elements = EXCLUDED.challenging_elements;

-- ============================================================================
-- MODALITIES (3)
-- ============================================================================
INSERT INTO public.astro_modalities (id, name, archetype, function_text, modern_keywords, season_marker) VALUES
('cardinal', 'Cardinal', 'initiator',
    'Starts each season; introduces a new pulse.',
    ARRAY['begin','launch','assert','lead','set direction'], 'start of season'),
('fixed',    'Fixed',    'sustainer',
    'Holds the middle of each season; consolidates and persists.',
    ARRAY['steady','commit','build out','hold','deepen'], 'middle of season'),
('mutable',  'Mutable',  'adapter',
    'Ends each season; bends and rearranges.',
    ARRAY['adjust','flex','translate','release','reshape'], 'end of season')
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    archetype = EXCLUDED.archetype,
    function_text = EXCLUDED.function_text,
    modern_keywords = EXCLUDED.modern_keywords,
    season_marker = EXCLUDED.season_marker;

-- ============================================================================
-- PLANETS (10)
-- ============================================================================
INSERT INTO public.astro_planets
    (id, name, glyph, type, archetype, function_text,
     is_personal, is_social, is_transpersonal,
     avg_speed_per_day_degrees, orbit_years, discovery_year,
     modern_keywords, sort_order, user_facing)
VALUES
('sun',     'Sun',     '☉', 'luminary',
    'vital self',
    'How a person shows up, where they shine, what they orient their life around.',
    TRUE, FALSE, FALSE, 0.9856, 1.0, NULL,
    ARRAY['identity','vitality','purpose','expression','will','leadership','presence'],
    0, TRUE),
('moon',    'Moon',    '☽', 'luminary',
    'emotional operating system',
    'How a person processes feelings, where they go to feel safe, their inner rhythm.',
    TRUE, FALSE, FALSE, 13.1764, 0.0748, NULL,
    ARRAY['emotion','instinct','safety','home','memory','mood','nurturing','inner life'],
    1, TRUE),
('mercury', 'Mercury', '☿', 'personal_planet',
    'the messenger',
    'How a person thinks, talks, learns, and links ideas together.',
    TRUE, FALSE, FALSE, 1.383, 0.2408, NULL,
    ARRAY['mind','language','curiosity','signal','exchange','learning','wit'],
    2, TRUE),
('venus',   'Venus',   '♀', 'personal_planet',
    'the connector',
    'What a person values, who they''re drawn to, how they experience pleasure and aesthetics.',
    TRUE, FALSE, FALSE, 1.602, 0.6152, NULL,
    ARRAY['attraction','pleasure','values','beauty','relating','grace','enjoyment'],
    3, TRUE),
('mars',    'Mars',    '♂', 'personal_planet',
    'the warrior',
    'How a person pursues, defends, competes, and acts on desire.',
    TRUE, FALSE, FALSE, 0.524, 1.881, NULL,
    ARRAY['drive','assertion','desire','conflict','action','energy','courage'],
    4, TRUE),
('jupiter', 'Jupiter', '♃', 'social_planet',
    'the expander',
    'Where a person grows, what they trust, and where they find meaning.',
    FALSE, TRUE, FALSE, 0.083, 11.862, NULL,
    ARRAY['growth','meaning','optimism','belief','expansion','exploration','reward'],
    5, TRUE),
('saturn',  'Saturn',  '♄', 'social_planet',
    'the structurer',
    'Where life asks for discipline, where limits surface, what gets built through time.',
    FALSE, TRUE, FALSE, 0.034, 29.457, NULL,
    ARRAY['structure','discipline','time','responsibility','mastery','limit','commitment'],
    6, TRUE),
('uranus',  'Uranus',  '♅', 'transpersonal_planet',
    'the disruptor',
    'Where the unexpected lands, where individuality breaks through convention.',
    FALSE, FALSE, TRUE, 0.0117, 84.011, 1781,
    ARRAY['liberation','disruption','innovation','signal','individuation','sudden change','clarity'],
    7, TRUE),
('neptune', 'Neptune', '♆', 'transpersonal_planet',
    'the dissolver',
    'Where boundaries blur, where imagination opens, where confusion can also hide.',
    FALSE, FALSE, TRUE, 0.006, 164.79, 1846,
    ARRAY['imagination','dissolution','dream','compassion','mystery','illusion','transcendence'],
    8, TRUE),
('pluto',   'Pluto',   '♇', 'transpersonal_planet',
    'the transformer',
    'Where a person undergoes deep change, faces power and shadow, and rebuilds from underneath.',
    FALSE, FALSE, TRUE, 0.004, 247.94, 1930,
    ARRAY['transformation','power','depth','rebirth','shadow','intensity','underworld'],
    9, TRUE)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name, glyph = EXCLUDED.glyph, type = EXCLUDED.type,
    archetype = EXCLUDED.archetype, function_text = EXCLUDED.function_text,
    is_personal = EXCLUDED.is_personal, is_social = EXCLUDED.is_social,
    is_transpersonal = EXCLUDED.is_transpersonal,
    avg_speed_per_day_degrees = EXCLUDED.avg_speed_per_day_degrees,
    orbit_years = EXCLUDED.orbit_years, discovery_year = EXCLUDED.discovery_year,
    modern_keywords = EXCLUDED.modern_keywords,
    sort_order = EXCLUDED.sort_order, user_facing = EXCLUDED.user_facing;

-- ============================================================================
-- POINTS (8) — non-planetary chart points the MVP surfaces.
--   astro_app_settings.supported_points_mvp lists exactly these 8 keys.
-- ============================================================================
-- The always_opposite FK is DEFERRABLE INITIALLY DEFERRED so we can insert
-- both halves of each opposite pair in one statement.
INSERT INTO public.astro_points
    (id, name, alternate_names, glyph, type, archetype, function_text,
     modern_keywords, calculation_method, is_house_cusp, always_opposite,
     user_facing, sort_order)
VALUES
('ascendant',         'Ascendant',         ARRAY['Rising','ASC'],  'AC', 'chart_angle',
    'how you arrive', 'The rising sign; how a person enters rooms, first impressions, the physical surface.',
    ARRAY['presentation','first impression','body','threshold'],
    'east horizon at birth time', 1, 'descendant', TRUE, 0),
('descendant',        'Descendant',        ARRAY['DSC'],            'DC', 'chart_angle',
    'who you meet', 'The setting horizon; the type of "other" a person attracts and partners with.',
    ARRAY['partnership','other','mirror','relating'],
    'west horizon at birth time', 7, 'ascendant', TRUE, 1),
('midheaven',         'Midheaven',         ARRAY['MC','Medium Coeli'], 'MC', 'chart_angle',
    'public direction', 'The highest visible point; vocation, public role, reputation, "what you''re known for".',
    ARRAY['vocation','public role','reputation','direction'],
    'culminating meridian at birth time', 10, 'imum_coeli', TRUE, 2),
('imum_coeli',        'Imum Coeli',        ARRAY['IC','Nadir'],     'IC', 'chart_angle',
    'private foundation', 'The lowest point; family of origin, home, inner roots, what you build on.',
    ARRAY['home','roots','origin','foundation'],
    'lower meridian at birth time', 4, 'midheaven', TRUE, 3),
('north_node',        'North Node',        ARRAY['True Node','Rahu','☊'], '☊', 'lunar_node',
    'the growth edge', 'Where a person is asked to develop and stretch in this life.',
    ARRAY['growth','development','direction','unfamiliar territory'],
    'true_node (mean_node available)', NULL, 'south_node', TRUE, 4),
('south_node',        'South Node',        ARRAY['Ketu','☋'],       '☋', 'lunar_node',
    'the familiar default', 'Where a person already has fluency; the comfort zone to consciously release.',
    ARRAY['comfort','default','release','familiarity'],
    'always 180° from north_node', NULL, 'north_node', TRUE, 5),
('chiron',            'Chiron',            ARRAY['The Wounded Healer'], '⚷', 'centaur',
    'the wound that teaches', 'Where deep sensitivity becomes a source of skill and care for others.',
    ARRAY['sensitivity','healing','teacher','wound'],
    'ephemeris position', NULL, NULL, TRUE, 6),
('black_moon_lilith', 'Black Moon Lilith', ARRAY['Lilith','Dark Moon'], '⚸', 'calculated_point',
    'the unowned self', 'Where instincts, refusals, and "no" carry information about what a person won''t betray.',
    ARRAY['refusal','wildness','sovereignty','undomesticated'],
    'mean_apogee (true_apogee available)', NULL, NULL, TRUE, 7)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name, alternate_names = EXCLUDED.alternate_names,
    glyph = EXCLUDED.glyph, type = EXCLUDED.type,
    archetype = EXCLUDED.archetype, function_text = EXCLUDED.function_text,
    modern_keywords = EXCLUDED.modern_keywords,
    calculation_method = EXCLUDED.calculation_method,
    is_house_cusp = EXCLUDED.is_house_cusp,
    always_opposite = EXCLUDED.always_opposite,
    user_facing = EXCLUDED.user_facing,
    sort_order = EXCLUDED.sort_order;

-- ============================================================================
-- SIGNS (12)
-- ============================================================================
INSERT INTO public.astro_signs
    (id, name, glyph, symbol, ordinal, element, modality, polarity,
     ruler, traditional_ruler, approximate_dates, season_northern_hemisphere,
     archetype, modern_keywords)
VALUES
('aries',       'Aries',       '♈', 'the ram',         1,  'fire',  'cardinal', 'active',
    'mars',     NULL,        'Mar 20 – Apr 19', 'spring',
    'initiator', ARRAY['begin','assert','spark','direct','first','brave']),
('taurus',      'Taurus',      '♉', 'the bull',        2,  'earth', 'fixed',    'receptive',
    'venus',    NULL,        'Apr 20 – May 20', 'spring',
    'builder', ARRAY['ground','enjoy','steady','provide','sense','hold']),
('gemini',      'Gemini',      '♊', 'the twins',       3,  'air',   'mutable',  'active',
    'mercury',  NULL,        'May 21 – Jun 20', 'spring',
    'messenger', ARRAY['curious','signal','translate','exchange','adapt','quick']),
('cancer',      'Cancer',      '♋', 'the crab',        4,  'water', 'cardinal', 'receptive',
    'moon',     NULL,        'Jun 21 – Jul 22', 'summer',
    'nurturer', ARRAY['care','protect','feel','home','memory','tend']),
('leo',         'Leo',         '♌', 'the lion',        5,  'fire',  'fixed',    'active',
    'sun',      NULL,        'Jul 23 – Aug 22', 'summer',
    'performer', ARRAY['shine','create','express','warm','play','heart']),
('virgo',       'Virgo',       '♍', 'the maiden',      6,  'earth', 'mutable',  'receptive',
    'mercury',  NULL,        'Aug 23 – Sep 22', 'summer',
    'analyst', ARRAY['refine','attend','serve','observe','adjust','craft']),
('libra',       'Libra',       '♎', 'the scales',      7,  'air',   'cardinal', 'active',
    'venus',    NULL,        'Sep 23 – Oct 22', 'autumn',
    'harmonizer', ARRAY['balance','relate','weigh','beauty','fair','elegant']),
('scorpio',     'Scorpio',     '♏', 'the scorpion',    8,  'water', 'fixed',    'receptive',
    'pluto',    'mars',      'Oct 23 – Nov 21', 'autumn',
    'alchemist', ARRAY['depth','transform','intimate','intensity','reveal','undercurrent']),
('sagittarius', 'Sagittarius', '♐', 'the archer',      9,  'fire',  'mutable',  'active',
    'jupiter',  NULL,        'Nov 22 – Dec 21', 'autumn',
    'seeker', ARRAY['quest','expand','believe','journey','meaning','horizon']),
('capricorn',   'Capricorn',   '♑', 'the goat',        10, 'earth', 'cardinal', 'receptive',
    'saturn',   NULL,        'Dec 22 – Jan 19', 'winter',
    'architect', ARRAY['structure','climb','commit','build','master','time']),
('aquarius',    'Aquarius',    '♒', 'the water bearer',11, 'air',   'fixed',    'active',
    'uranus',   'saturn',    'Jan 20 – Feb 18', 'winter',
    'visionary', ARRAY['systems','disrupt','collective','signal','individuate','liberate']),
('pisces',      'Pisces',      '♓', 'the fish',        12, 'water', 'mutable',  'receptive',
    'neptune',  'jupiter',   'Feb 19 – Mar 19', 'winter',
    'mystic', ARRAY['dream','dissolve','imagine','feel','permeate','compassion'])
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name, glyph = EXCLUDED.glyph, symbol = EXCLUDED.symbol,
    ordinal = EXCLUDED.ordinal, element = EXCLUDED.element,
    modality = EXCLUDED.modality, polarity = EXCLUDED.polarity,
    ruler = EXCLUDED.ruler, traditional_ruler = EXCLUDED.traditional_ruler,
    approximate_dates = EXCLUDED.approximate_dates,
    season_northern_hemisphere = EXCLUDED.season_northern_hemisphere,
    archetype = EXCLUDED.archetype, modern_keywords = EXCLUDED.modern_keywords;

-- ============================================================================
-- HOUSES (12)
-- ============================================================================
INSERT INTO public.astro_houses
    (ordinal, name, alternate_names, polarity, weight,
     associated_sign, associated_planet, associated_planet_traditional,
     cusp_is_chart_angle, domain, modern_keywords)
VALUES
(1,  'Self',         ARRAY['House of Self'],        'angular',   'high',
    'aries',       'mars',    NULL,      'ascendant',
    'self, presentation, physical body, first impressions',
    ARRAY['identity','arrival','body','threshold']),
(2,  'Resources',    ARRAY['House of Value'],       'succedent', 'medium',
    'taurus',      'venus',   NULL,      NULL,
    'money, possessions, values, self-worth, income',
    ARRAY['value','money','possessions','self-worth']),
(3,  'Mind',         ARRAY['House of Communication'], 'cadent',  'low',
    'gemini',      'mercury', NULL,      NULL,
    'communication, siblings, neighbors, short trips, daily learning',
    ARRAY['signal','siblings','local','daily']),
(4,  'Home',         ARRAY['House of Roots'],       'angular',   'high',
    'cancer',      'moon',    NULL,      'imum_coeli',
    'home, family, roots, foundation',
    ARRAY['home','family','origin','foundation']),
(5,  'Creation',     ARRAY['House of Pleasure'],    'succedent', 'medium',
    'leo',         'sun',     NULL,      NULL,
    'creativity, romance, children, play, self-expression',
    ARRAY['create','romance','children','play']),
(6,  'Craft',        ARRAY['House of Service'],     'cadent',    'low',
    'virgo',       'mercury', NULL,      NULL,
    'daily work, routine, health practices, service',
    ARRAY['work','routine','health','craft']),
(7,  'Partnership',  ARRAY['House of Other'],       'angular',   'high',
    'libra',       'venus',   NULL,      'descendant',
    'partnership, marriage, contracts, projection',
    ARRAY['partner','marriage','contract','mirror']),
(8,  'Depth',        ARRAY['House of Transformation'], 'succedent','medium',
    'scorpio',     'pluto',   'mars',    NULL,
    'intimacy, shared resources, transformation, taboo',
    ARRAY['intimacy','shared resources','transform','taboo']),
(9,  'Horizons',     ARRAY['House of Meaning'],     'cadent',    'low',
    'sagittarius', 'jupiter', NULL,      NULL,
    'philosophy, higher education, long travel, meaning',
    ARRAY['philosophy','travel','study','meaning']),
(10, 'Vocation',     ARRAY['House of Career'],      'angular',   'high',
    'capricorn',   'saturn',  NULL,      'midheaven',
    'career, public role, reputation, authority',
    ARRAY['career','public role','reputation','authority']),
(11, 'Community',    ARRAY['House of Friends'],     'succedent', 'medium',
    'aquarius',    'uranus',  'saturn',  NULL,
    'friends, networks, community, future hopes',
    ARRAY['friends','network','community','vision']),
(12, 'Inner',        ARRAY['House of Solitude'],    'cadent',    'low',
    'pisces',      'neptune', 'jupiter', NULL,
    'unconscious, solitude, dreams, spirituality, hidden patterns',
    ARRAY['unconscious','solitude','dream','spiritual'])
ON CONFLICT (ordinal) DO UPDATE SET
    name = EXCLUDED.name, alternate_names = EXCLUDED.alternate_names,
    polarity = EXCLUDED.polarity, weight = EXCLUDED.weight,
    associated_sign = EXCLUDED.associated_sign,
    associated_planet = EXCLUDED.associated_planet,
    associated_planet_traditional = EXCLUDED.associated_planet_traditional,
    cusp_is_chart_angle = EXCLUDED.cusp_is_chart_angle,
    domain = EXCLUDED.domain,
    modern_keywords = EXCLUDED.modern_keywords;

-- ============================================================================
-- DIGNITIES (47)
-- Scheme:
--   - 12 'rulership' rows: one per (planet, sign) modern-rulership pair.
--     Mercury rules gemini AND virgo. Venus rules taurus AND libra.
--   - 10 'exaltation' rows: one per planet.
--   - 12 'detriment' rows: one per planet's detriment sign(s).
--     Mercury detriments: sagittarius (opp gemini) AND pisces (opp virgo).
--     Venus detriments: scorpio (opp taurus) AND aries (opp libra).
--   - 10 'fall' rows: one per planet (opposite of exaltation).
--   - 3 'traditional_rulership' rows: mars→scorpio, jupiter→pisces, saturn→aquarius.
-- Total = 12 + 10 + 12 + 10 + 3 = 47.
-- ============================================================================
INSERT INTO public.astro_dignities (planet_id, sign_id, dignity_type) VALUES
-- Modern rulerships (12)
('sun',     'leo',         'rulership'),
('moon',    'cancer',      'rulership'),
('mercury', 'gemini',      'rulership'),
('mercury', 'virgo',       'rulership'),
('venus',   'taurus',      'rulership'),
('venus',   'libra',       'rulership'),
('mars',    'aries',       'rulership'),
('jupiter', 'sagittarius', 'rulership'),
('saturn',  'capricorn',   'rulership'),
('uranus',  'aquarius',    'rulership'),
('neptune', 'pisces',      'rulership'),
('pluto',   'scorpio',     'rulership'),
-- Exaltations (10)
('sun',     'aries',       'exaltation'),
('moon',    'taurus',      'exaltation'),
('mercury', 'virgo',       'exaltation'),
('venus',   'pisces',      'exaltation'),
('mars',    'capricorn',   'exaltation'),
('jupiter', 'cancer',      'exaltation'),
('saturn',  'libra',       'exaltation'),
('uranus',  'scorpio',     'exaltation'),
('neptune', 'leo',         'exaltation'),
('pluto',   'aries',       'exaltation'),
-- Detriments (12)
('sun',     'aquarius',    'detriment'),
('moon',    'capricorn',   'detriment'),
('mercury', 'sagittarius', 'detriment'),
('mercury', 'pisces',      'detriment'),
('venus',   'scorpio',     'detriment'),
('venus',   'aries',       'detriment'),
('mars',    'libra',       'detriment'),
('jupiter', 'gemini',      'detriment'),
('saturn',  'cancer',      'detriment'),
('uranus',  'leo',         'detriment'),
('neptune', 'virgo',       'detriment'),
('pluto',   'taurus',      'detriment'),
-- Falls (10)
('sun',     'libra',       'fall'),
('moon',    'scorpio',     'fall'),
('mercury', 'pisces',      'fall'),
('venus',   'virgo',       'fall'),
('mars',    'cancer',      'fall'),
('jupiter', 'capricorn',   'fall'),
('saturn',  'aries',       'fall'),
('uranus',  'taurus',      'fall'),
('neptune', 'aquarius',    'fall'),
('pluto',   'libra',       'fall'),
-- Traditional rulerships pre-outer-planet discovery (3)
('mars',    'scorpio',     'traditional_rulership'),
('jupiter', 'pisces',      'traditional_rulership'),
('saturn',  'aquarius',    'traditional_rulership')
ON CONFLICT (planet_id, sign_id, dignity_type) DO NOTHING;

-- ============================================================================
-- ASPECTS (11) — 5 major + 6 minor.
-- ============================================================================
INSERT INTO public.astro_aspects
    (id, name, alternate_names, glyph, degrees, default_orb, valence, polarity, description, is_major, synastry_orb)
VALUES
-- Major (is_major = TRUE)
('conjunction', 'Conjunction', ARRAY['Conj'], '☌',   0, 8, 'merging',     'neutral',
    'Two planets occupy the same point in the chart; their energies fuse.',  TRUE,  8),
('sextile',     'Sextile',     ARRAY['Sex'],  '⚹',  60, 6, 'cooperative', 'harmonious',
    'A supportive opening between planets; flow that responds to effort.',     TRUE,  5),
('square',      'Square',      ARRAY['Sq'],   '□',  90, 8, 'frictional',  'challenging',
    'Two planets pull against each other; tension that demands resolution.',  TRUE,  6),
('trine',       'Trine',       ARRAY['Tri'],  '△', 120, 8, 'flowing',     'harmonious',
    'Two planets in the same element; an easy current that risks complacency.', TRUE, 6),
('opposition',  'Opposition',  ARRAY['Opp'],  '☍', 180, 8, 'polarizing',  'challenging',
    'Two planets directly across; a mirror dynamic that asks for integration.', TRUE,  8),
-- Minor (is_major = FALSE)
('semisextile',     'Semisextile',     ARRAY[]::TEXT[], NULL,  30, 2, 'mild friction', 'neutral',
    'A subtle adjustment between two neighboring signs.', FALSE, 1),
('semisquare',      'Semisquare',      ARRAY[]::TEXT[], '∠',   45, 2, 'low friction',  'challenging',
    'A small but persistent irritation that asks for refinement.', FALSE, 2),
('quintile',        'Quintile',        ARRAY[]::TEXT[], NULL,  72, 2, 'creative',      'harmonious',
    'A creative spark; a niche signature talent connecting two planets.', FALSE, 1),
('sesquiquadrate',  'Sesquiquadrate',  ARRAY['Sesquisquare'], '⚼', 135, 2, 'recurring friction', 'challenging',
    'A pattern of pressure that repeats until acknowledged.', FALSE, 2),
('biquintile',      'Biquintile',      ARRAY[]::TEXT[], NULL, 144, 2, 'creative',      'harmonious',
    'Another creative talent aspect; subtler than the quintile.', FALSE, 1),
('quincunx',        'Quincunx',        ARRAY['Inconjunct'], '⚻', 150, 3, 'awkward',     'neutral',
    'Two planets with no shared element or modality; requires conscious bridging.', FALSE, 2)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name, alternate_names = EXCLUDED.alternate_names,
    glyph = EXCLUDED.glyph, degrees = EXCLUDED.degrees,
    default_orb = EXCLUDED.default_orb, valence = EXCLUDED.valence,
    polarity = EXCLUDED.polarity, description = EXCLUDED.description,
    is_major = EXCLUDED.is_major, synastry_orb = EXCLUDED.synastry_orb;

-- ============================================================================
-- LUNAR PHASES (8)
-- ============================================================================
INSERT INTO public.astro_lunar_phases
    (id, name, alternate_names, ordinal,
     sun_moon_angle_min, sun_moon_angle_max,
     archetype, function_text, modern_keywords)
VALUES
('new_moon',        'New Moon',        ARRAY['Dark Moon'], 1,   0,  45,
    'the seed',
    'A fresh cycle begins below the surface — set the intention before it can show itself.',
    ARRAY['seed','intention','start','dark','beginning']),
('waxing_crescent', 'Waxing Crescent', ARRAY[]::TEXT[],    2,  45,  90,
    'the gathering',
    'Building momentum from the intention; gathering resources and clarity.',
    ARRAY['gather','momentum','believe','support']),
('first_quarter',   'First Quarter',   ARRAY['Half Moon'], 3,  90, 135,
    'the test',
    'A pressure point where the intention meets resistance and must be defended.',
    ARRAY['test','effort','decide','push']),
('waxing_gibbous',  'Waxing Gibbous',  ARRAY[]::TEXT[],    4, 135, 180,
    'the refinement',
    'Almost full; adjust the form before the moment of reveal.',
    ARRAY['refine','prepare','adjust','almost']),
('full_moon',       'Full Moon',       ARRAY[]::TEXT[],    5, 180, 225,
    'the revelation',
    'Maximum illumination; the cycle''s peak — what was hidden is now visible.',
    ARRAY['reveal','peak','culminate','visible']),
('waning_gibbous',  'Waning Gibbous',  ARRAY['Disseminating Moon'], 6, 225, 270,
    'the distribution',
    'Sharing what the cycle produced; teaching, harvesting, communicating.',
    ARRAY['share','harvest','teach','distribute']),
('last_quarter',    'Last Quarter',    ARRAY['Third Quarter'], 7, 270, 315,
    'the reckoning',
    'An honest review; release what is finished, keep what is still alive.',
    ARRAY['review','release','prune','reckon']),
('waning_crescent', 'Waning Crescent', ARRAY['Balsamic Moon'], 8, 315, 360,
    'the rest',
    'Composting; the empty interval before the next seeding.',
    ARRAY['rest','compost','empty','prepare-anew'])
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name, alternate_names = EXCLUDED.alternate_names,
    ordinal = EXCLUDED.ordinal,
    sun_moon_angle_min = EXCLUDED.sun_moon_angle_min,
    sun_moon_angle_max = EXCLUDED.sun_moon_angle_max,
    archetype = EXCLUDED.archetype, function_text = EXCLUDED.function_text,
    modern_keywords = EXCLUDED.modern_keywords;

-- ============================================================================
-- DECANS (36) — Chaldean order along the element.
--   Fire (aries, leo, sag):     [mars,    sun,     jupiter]  cycled
--   Earth (taurus, virgo, cap): [venus,   mercury, saturn]   cycled
--   Air (gemini, libra, aqua):  [mercury, venus,   uranus]   cycled (modern)
--   Water (cancer, scorpio, pisces): [moon, pluto, neptune]  cycled (modern)
-- ============================================================================
INSERT INTO public.astro_decans (sign_id, decan_number, degree_start, degree_end, sub_ruler, flavor) VALUES
-- Fire
('aries',       1,  0, 10, 'mars',    'pure assertion; the spark before refinement'),
('aries',       2, 10, 20, 'sun',     'aries with warmth and identity — the leader-Aries'),
('aries',       3, 20, 30, 'jupiter', 'aries with vision and excess — the philosopher-Aries'),
('leo',         1,  0, 10, 'sun',     'pure radiance; classic leo presence'),
('leo',         2, 10, 20, 'jupiter', 'leo with generosity and big-picture warmth'),
('leo',         3, 20, 30, 'mars',    'leo with edge and competition; performance with bite'),
('sagittarius', 1,  0, 10, 'jupiter', 'pure quest; classic sagittarian seeking'),
('sagittarius', 2, 10, 20, 'mars',    'sag with conviction and crusade'),
('sagittarius', 3, 20, 30, 'sun',     'sag with confidence and a teaching streak'),
-- Earth
('taurus',      1,  0, 10, 'venus',   'pure embodied pleasure and steadiness'),
('taurus',      2, 10, 20, 'mercury', 'taurus that articulates value and craft'),
('taurus',      3, 20, 30, 'saturn',  'taurus with discipline; the slow architect'),
('virgo',       1,  0, 10, 'mercury', 'pure analytic precision and craft'),
('virgo',       2, 10, 20, 'saturn',  'virgo with structure; the long-game builder'),
('virgo',       3, 20, 30, 'venus',   'virgo with aesthetic refinement; the editor'),
('capricorn',   1,  0, 10, 'saturn',  'pure structural ambition'),
('capricorn',   2, 10, 20, 'venus',   'capricorn with aesthetic; the elegant builder'),
('capricorn',   3, 20, 30, 'mercury', 'capricorn with strategy; the systems thinker'),
-- Air (modern rulers)
('gemini',      1,  0, 10, 'mercury', 'pure curiosity and quick exchange'),
('gemini',      2, 10, 20, 'venus',   'gemini with charm; the social connector'),
('gemini',      3, 20, 30, 'uranus',  'gemini with electricity; the inventor-Gemini'),
('libra',       1,  0, 10, 'venus',   'pure harmony and aesthetic balance'),
('libra',       2, 10, 20, 'uranus',  'libra with originality; the unconventional partner'),
('libra',       3, 20, 30, 'mercury', 'libra with discourse; the diplomat'),
('aquarius',    1,  0, 10, 'uranus',  'pure individuation; classic aquarian signal'),
('aquarius',    2, 10, 20, 'mercury', 'aquarius with discourse; the explainer'),
('aquarius',    3, 20, 30, 'venus',   'aquarius with relating warmth; the community-builder'),
-- Water (modern rulers)
('cancer',      1,  0, 10, 'moon',    'pure emotional tide; classic cancerian care'),
('cancer',      2, 10, 20, 'pluto',   'cancer with depth and protective intensity'),
('cancer',      3, 20, 30, 'neptune', 'cancer with imagination; dreamy nurturance'),
('scorpio',     1,  0, 10, 'pluto',   'pure depth and transformation'),
('scorpio',     2, 10, 20, 'neptune', 'scorpio with mystery; the seer'),
('scorpio',     3, 20, 30, 'moon',    'scorpio with feeling; emotional alchemy'),
('pisces',      1,  0, 10, 'neptune', 'pure dissolution; classic piscean openness'),
('pisces',      2, 10, 20, 'moon',    'pisces with deep feeling; the empath'),
('pisces',      3, 20, 30, 'pluto',   'pisces with intensity; the depth diver')
ON CONFLICT (sign_id, decan_number) DO UPDATE SET
    degree_start = EXCLUDED.degree_start,
    degree_end   = EXCLUDED.degree_end,
    sub_ruler    = EXCLUDED.sub_ruler,
    flavor       = EXCLUDED.flavor;

-- ============================================================================
-- HOUSE SYSTEMS (4)
-- ============================================================================
INSERT INTO public.astro_house_systems (id, name, method, best_for, limitation, is_default) VALUES
('placidus',    'Placidus',    'time-based division of the diurnal arc',
    'modern Western default; emphasizes the moment of birth',
    'breaks down at very high or very low latitudes', TRUE),
('whole_sign',  'Whole Sign',  'each sign occupies one full house',
    'traditional and Hellenistic charts; clean and unambiguous',
    'less granular than time-based methods', FALSE),
('koch',        'Koch',        'birthplace-specific time division similar to Placidus',
    'works well at moderate latitudes',
    'similar high-latitude issues to Placidus', FALSE),
('equal_house', 'Equal House', 'each house exactly 30° from the ascendant',
    'always works at any latitude; clean and uniform',
    'midheaven may not align with the 10th cusp', FALSE)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name, method = EXCLUDED.method,
    best_for = EXCLUDED.best_for, limitation = EXCLUDED.limitation,
    is_default = EXCLUDED.is_default;

-- ============================================================================
-- SYNASTRY PATTERNS (14)
-- ============================================================================
INSERT INTO public.astro_synastry_patterns (pattern_key, pattern_type, description, weight) VALUES
-- High significance (6)
('sun_moon_any_aspect',         'high_significance',
    'A Sun–Moon connection between two people: identity meets emotional rhythm.',  8),
('moon_moon_any_aspect',        'high_significance',
    'Two Moons aspecting each other: how the inner worlds blend or chafe.',         8),
('venus_mars_any_aspect',       'high_significance',
    'Venus and Mars connecting: relational chemistry and erotic charge.',           8),
('ascendant_sun_or_moon',       'high_significance',
    'One person''s Ascendant aligns with the other''s Sun or Moon: instant resonance at first encounter.', 8),
('saturn_personal_planet',      'high_significance',
    'Saturn touching a personal planet between two charts: long-term lessons and commitments.',  8),
('node_personal_planet',        'high_significance',
    'A lunar node connecting to the other''s personal planet: a karmic or directional theme.',    8),
-- Challenging (4)
('saturn_square_or_opposite_personal_planet', 'challenging',
    'Saturn pressing on the other''s personal planet: the relationship slows, structures, or tests.', 5),
('mars_square_or_opposite_mars', 'challenging',
    'Two Mars in friction: collisions of will, drive, and method.',                                  5),
('moon_square_or_opposite_moon', 'challenging',
    'Two Moons in friction: emotional tempos mismatched; needs require translation.',               5),
('pluto_aspecting_personal_planet', 'challenging',
    'Pluto on the other''s personal planet: deep transformation, sometimes uncomfortable.',         5),
-- Harmonious (4)
('sun_trine_or_sextile_moon',   'harmonious',
    'Sun in flowing aspect to Moon: identity and emotion support each other.',                      5),
('venus_trine_or_sextile_jupiter', 'harmonious',
    'Venus and Jupiter flowing: warmth, generosity, expansive affection.',                          5),
('moon_in_partners_4th_house',  'harmonious',
    'One person''s Moon falls in the partner''s 4th house: domestic ease and shared home rhythm.',  5),
('venus_in_partners_5th_or_7th_house', 'harmonious',
    'Venus lands in the partner''s 5th or 7th: romantic delight and partnership chemistry.',        5)
ON CONFLICT (pattern_key) DO UPDATE SET
    pattern_type = EXCLUDED.pattern_type,
    description  = EXCLUDED.description,
    weight       = EXCLUDED.weight;

-- ============================================================================
-- MOON COMPATIBILITY (16) — 4 elements × 4 elements (full cross-product).
-- ============================================================================
INSERT INTO public.astro_moon_compatibility (element_a, element_b, compatibility, description) VALUES
('fire',  'fire',  'high',
    'Two fire moons share the same emotional fuel: warmth, momentum, and direct response.'),
('fire',  'air',   'high',
    'Fire and air feed each other: enthusiasm meets curiosity, neither overwhelms.'),
('fire',  'earth', 'challenging',
    'Fire wants motion; earth wants steadiness. The pace mismatch needs translation.'),
('fire',  'water', 'challenging',
    'Fire dries water; water cools fire. Emotional intensity reads differently to each.'),
('earth', 'earth', 'high',
    'Two earth moons settle into a shared rhythm of practical care and reliability.'),
('earth', 'water', 'high',
    'Earth contains water; water softens earth. Deeply nourishing for both.'),
('earth', 'fire',  'challenging',
    'Earth needs slow steadiness; fire wants urgency. Translation: patience plus play.'),
('earth', 'air',   'challenging',
    'Earth experiences feelings in the body; air processes them as ideas. Different languages.'),
('air',   'air',   'high',
    'Two air moons love to think aloud together. The rare risk is talking past the feeling.'),
('air',   'fire',  'high',
    'Mirror of fire+air: lively, idea-rich connection.'),
('air',   'earth', 'challenging',
    'Mirror of earth+air: a chronic translation gap between concept and felt sense.'),
('air',   'water', 'challenging',
    'Air abstracts; water immerses. Each can feel unmet by the other.'),
('water', 'water', 'high',
    'Two water moons read each other''s undercurrents instantly. The risk is recursion.'),
('water', 'earth', 'high',
    'Mirror of earth+water: deeply nourishing, slow, intimate.'),
('water', 'fire',  'challenging',
    'Mirror of fire+water: emotional weather mismatches.'),
('water', 'air',   'challenging',
    'Mirror of air+water: feelings asked to defend themselves verbally.')
ON CONFLICT (element_a, element_b) DO UPDATE SET
    compatibility = EXCLUDED.compatibility,
    description   = EXCLUDED.description;

-- ============================================================================
-- TRANSIT SIGNIFICANCE (10)
-- ============================================================================
INSERT INTO public.astro_transit_significance
    (transit_pattern, significance, description, user_alert_default)
VALUES
('outer_planet_transits_to_personal_planets', 'highest',
    'When Uranus/Neptune/Pluto contact your personal planets — life-defining periods.', TRUE),
('saturn_return', 'highest',
    'Saturn returning to its natal sign every ~29 years; major maturation thresholds.',  TRUE),
('outer_planet_to_angles', 'highest',
    'Uranus/Neptune/Pluto crossing the Ascendant, MC, IC, or Descendant: identity-level events.', TRUE),
('progressed_lunar_phases', 'highest',
    'The 27.5-year progressed Moon cycle reframes inner life in eight chapters.',          TRUE),
('jupiter_returns', 'moderate',
    'Jupiter returning to its natal position every ~12 years; growth checkpoints.',         FALSE),
('jupiter_to_personal_planets', 'moderate',
    'Jupiter contacts to personal planets: expansion and opportunity windows.',             FALSE),
('saturn_to_houses', 'moderate',
    'Saturn moving through a house: that life domain is asked to mature.',                  FALSE),
('mercury_retrograde', 'low',
    'Mercury retrograde; useful for review and revision more than launches.',               FALSE),
('venus_retrograde', 'low',
    'Venus retrograde; relationship and value patterns surface for honest reassessment.',   FALSE),
('mars_retrograde', 'low',
    'Mars retrograde; drive and direction get reassessed before re-engaging.',              FALSE)
ON CONFLICT (transit_pattern) DO UPDATE SET
    significance = EXCLUDED.significance,
    description = EXCLUDED.description,
    user_alert_default = EXCLUDED.user_alert_default;

-- ============================================================================
-- APP SETTINGS (13)
-- ============================================================================
INSERT INTO public.astro_app_settings (key, value, description) VALUES
('default_house_system',              '"placidus"'::jsonb,
    'The house system used when calculating natal charts.'),
('default_zodiac',                    '"tropical"'::jsonb,
    'Tropical (Western) vs sidereal (Vedic) zodiac. MVP uses tropical.'),
('default_node_calculation',          '"true_node"'::jsonb,
    'Mean node (smooth orbital average) vs true node (instantaneous position).'),
('default_lilith_calculation',        '"mean_apogee"'::jsonb,
    'Mean (smoothed) vs true (instantaneous) vs natural apogee for Black Moon Lilith.'),
('fallback_house_system_high_latitude', '"whole_sign"'::jsonb,
    'House system used when birth latitude makes Placidus undefined (e.g., near poles).'),
('use_traditional_rulerships',        'false'::jsonb,
    'When TRUE, Pluto-rulership of Scorpio yields to Mars; Uranus/Aquarius yields to Saturn; Neptune/Pisces yields to Jupiter.'),
('preferred_aspect_orbs',             '"default"'::jsonb,
    'Aspect orb tightness: "default", "tight" (smaller orbs), or "generous" (larger orbs).'),
('show_minor_aspects',                'false'::jsonb,
    'Whether to surface semisextile, semisquare, quintile, etc. MVP hides minors by default.'),
('supported_planets_mvp',
    '["sun","moon","mercury","venus","mars","jupiter","saturn","uranus","neptune","pluto"]'::jsonb,
    'The exact planet set the MVP UI exposes.'),
('supported_points_mvp',
    '["ascendant","midheaven","descendant","imum_coeli","north_node","south_node","chiron","black_moon_lilith"]'::jsonb,
    'Non-planetary chart points the MVP UI exposes.'),
('user_facing_planet_order',
    '["sun","moon","mercury","venus","mars","jupiter","saturn","uranus","neptune","pluto","chiron","north_node","south_node","black_moon_lilith"]'::jsonb,
    'Order in which planets and points are listed in user-facing UI.'),
('user_facing_voice_rules',
    '{"tone":"calm, observational","forbid":["malefic","benefic","cursed","blessed","negative chart"],"prefer":["pattern","texture","invitation","tendency"]}'::jsonb,
    'Voice constraints applied to AI-generated content for Moon Rhythms.'),
('future_additions',
    '["part_of_fortune","vertex","ceres","pallas","juno","vesta"]'::jsonb,
    'Bodies and points reserved for post-MVP introduction.')
ON CONFLICT (key) DO UPDATE SET
    value = EXCLUDED.value,
    description = EXCLUDED.description,
    updated_at = NOW();

-- ============================================================================
-- OVERRIDABLE PREFERENCES (7)
-- All advanced_user_only = TRUE for MVP. None surface in UI yet.
-- ============================================================================
INSERT INTO public.astro_overridable_preferences
    (key, label, description, valid_values, advanced_user_only, sort_order)
VALUES
('default_house_system',           'House System',
    'Which house system to use when calculating charts.',
    '["placidus","whole_sign","koch","equal_house"]'::jsonb, TRUE, 10),
('default_zodiac',                 'Zodiac System',
    'Tropical (default) or sidereal.',
    '["tropical","sidereal"]'::jsonb, TRUE, 20),
('use_traditional_rulerships',     'Use Traditional Rulerships',
    'If TRUE, the outer-planet rulerships are demoted in favor of classical rulers.',
    '[true,false]'::jsonb, TRUE, 30),
('default_node_calculation',       'Lunar Node Calculation',
    'Mean (smoothed) or true (instantaneous) lunar node.',
    '["mean_node","true_node"]'::jsonb, TRUE, 40),
('default_lilith_calculation',     'Black Moon Lilith Calculation',
    'Mean, true, or natural apogee for Black Moon Lilith.',
    '["mean_apogee","true_apogee","natural_apogee"]'::jsonb, TRUE, 50),
('preferred_aspect_orbs',          'Aspect Orb Tightness',
    'How much wiggle room around each aspect''s exact degree.',
    '["default","tight","generous"]'::jsonb, TRUE, 60),
('show_minor_aspects',             'Show Minor Aspects',
    'If TRUE, the UI surfaces semisextile, semisquare, quintile, etc.',
    '[true,false]'::jsonb, TRUE, 70)
ON CONFLICT (key) DO UPDATE SET
    label = EXCLUDED.label,
    description = EXCLUDED.description,
    valid_values = EXCLUDED.valid_values,
    advanced_user_only = EXCLUDED.advanced_user_only,
    sort_order = EXCLUDED.sort_order;
