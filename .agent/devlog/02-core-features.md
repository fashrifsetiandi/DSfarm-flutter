# Week 3-4: Core Features

## Kandang (Housing)
- [x] Housing model dengan type & status
- [x] Housing CRUD operations
- [x] Assignment ke livestock

## Livestock (Indukan)
- [x] Livestock model dengan gender, breed, status
- [x] Auto-generate code: `[BREED]-[J/B][SEQ]`
- [x] Livestock list & detail screens

## Breeding Records
- [x] BreedingRecord model
- [x] Mating → Palpation → Birth → Weaning flow
- [x] Auto-create reminders
- [x] Status progression

## Offspring (Anakan)
- [x] Offspring model dengan status progression
- [x] Auto-code: `[DAM]-[SIRE]-[DATE]-[SEQ]`
- [x] Create from birth event
- [x] Status: infarm → weaned → ready_sell → sold

## Key Learnings
- Complex form dengan DatePicker
- Cascading dropdown (block → kandang)
- Status progression patterns
