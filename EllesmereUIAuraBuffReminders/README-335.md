# EllesmereUI AuraBuff Reminders — Wrath 3.3.5a — 0.3

Executam apenas os quatro arquivos EUI_AuraBuffReminders_335 (Catalog, Display,
principal e Extras). Os Lua Retail (principal e TalentReminders) e os sons
ficam idênticos ao Retail, só como referência. Requer EllesmereUI.

0.3 porta as funções e o visual do Retail que existem no Wrath:

- Schema de perfil do Retail (display/raidBuffs/auras/consumables/custom/
  talentReminders), com migração automática do schema 0.1 por chave.
- Raid buffs com botão de provedor: o buff de grupo (Prayer of Fortitude,
  Gift of the Wild, Greater Blessings, Arcane Brilliance…) é lançado pelo nome
  (rank mais alto) no primeiro membro sem o buff, com contagem "tem/total".
  O botão seguro é posicionado fora de combate e continua clicável em combate.
- Auras/armaduras/presenças/aspectos por classe e spec (árvore dominante),
  escudos de Shaman (Earth Shield no tank/focus), imbues por mão, venenos de
  Rogue (item + mão), Runeforging de DK, pets de Hunter/Warlock/DK (ciclo com
  botão direito, demônio errado, Demonic Sacrifice, pet em passivo),
  Soulstone e Healthstone.
- Flask/elixir/comida com estoque, preferência clicável, item substituto,
  contagem de bolsa e contagem regressiva enquanto come.
- Onde mostrar (mundo, dungeon normal/heroica, raid normal/heroica, em
  combate), Show Below (segundos), sons por categoria, glow, borda, fontes,
  texto, opacidade, direção de crescimento, ícones no cursor, Unlock Mode.
- Lembretes customizados por ID de aura e Ready Check Warning de mana para
  healers. Talent Reminders: zonas do Wrath + instância atual, talentos via
  GetTalentInfo com IDs sintéticos, aviso "(N/N)".
- Clique do meio dispensa até a próxima tela de carregamento.

Não portado (não existe no 3.3.5a): augment runes, Inky Black, Coach's
Whistle, qualidade de crafting, Beacons/Rites de Paladin, auras de Evoker,
Symbiotic Relationship, limite Pre-Key de M+, LibSpecialization, Hunter's
Mark, identidade exata do imbue/veneno por mão (GetWeaponEnchantInfo sem ID),
unit/filtro/ownOnly nos customizados, Water Elemental e filtro de zonas por
temporada.

validate_aurabuffreminders.py testa migração, botão de provedor, overlays,
segurança em combate, consumíveis, onde mostrar, sons, customizados, classes,
talentos, ready check, unlock, slash e monta as duas páginas de opções reais.
Aparência e ações seguras ainda precisam de revisão no cliente.
