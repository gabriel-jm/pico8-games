class Item {
  constructor(name, type, stat1, stat2, minf, maxf, desc = '') {
    this.name = name
    this.type = type
    this.stat1 = stat1
    this.stat2 = stat2
    this.minf = minf
    this.maxf = maxf
    this.desc = desc
  }
}

class Monster {
  constructor(name, sprs, atk, hp, los, minf, maxf, spec = '') {
    this.name = name
    this.sprs = sprs
    this.atk = atk
    this.hp = hp
    this.los = los
    this.minf = minf
    this.maxf = maxf
    this.spec = spec
  }
}

const itemsList = [
  new Item('butter knife', 'wep', 1, 0, 1, 3),
  new Item('cheese knife', 'wep', 2, 0, 2, 4),
  new Item('paring knife', 'wep', 3, 0, 3, 5),
  new Item('utility knife', 'wep', 4, 0, 4, 6),
  new Item('chef\'s knife', 'wep', 5, 0, 5, 7),
  new Item('meat cleaver', 'wep', 6, 0, 6, 8),
  new Item('paper apron', 'arm', 0, 1, 1, 3),
  new Item('cotton apron', 'arm', 0, 2, 2, 4),
  new Item('rubber apron', 'arm', 0, 3, 3, 5),
  new Item('leather apron', 'arm', 0, 4, 4, 6),
  new Item('chef\'s apron', 'arm', 1, 3, 5, 7),
  new Item('butcher\'s apron', 'arm', 2, 3, 6, 8),
  new Item('food 1', 'fud', 1, 0, 1, 8, 'heals'), //heals
  new Item('food 2', 'fud', 2, 0, 1, 8, 'heals a lot'), //heals a lot
  new Item('food 3', 'fud', 3, 0, 1, 8, 'increase hp'), //increase hp
  new Item('food 4', 'fud', 4, 0, 1, 8, 'stun'), //stun
  new Item('food 5', 'fud', 5, 0, 1, 8, 'is cursed'), //is cursed
  new Item('food 6', 'fud', 6, 0, 1, 8, 'is blessed'), //is blessed
  new Item('spork', 'thr', 1, 0, 1, 4),
  new Item('salad fork', 'thr', 2, 0, 2, 6),
  new Item('fish fork', 'thr', 3, 0, 3, 7),
  new Item('dinner fork', 'thr', 4, 0, 4, 8)
]

const monstersList = [
  new Monster('player', 240, 1, 5, 4, 0, 0),
  new Monster('slime', 192, 1, 1, 4, 1, 3),
  new Monster('melt', 196, 2, 2, 4, 2, 4),
  new Monster('shoggoth', 200, 2, 3, 4, 3, 5, 'spawn'), //spawn?
  new Monster('mantis-man', 204, 2, 3, 4, 4, 6, 'fast'), //fast?
  new Monster('giant scorpion', 208, 3, 4, 4, 5, 7, 'stun'), //stun
  new Monster('ghost', 212, 3, 5, 4, 6, 8, 'ghost'), //ghost
  new Monster('golem', 216, 5, 14, 4, 7, 8, 'slow'), //slow
  new Monster('drake', 220, 5, 8, 4, 8, 8)
]

function generateTable(prefix, initialList) {
  const typeList = initialList.reduce((acc, value, index) => {
    Object.keys(value).forEach(key => {
      acc[key] = index === initialList.length - 1
        ? acc[key] + value[key]
        : (acc[key] || '') + value[key] + ','
    })

    return acc
  }, {})

  const tablesList = Object.keys(typeList).map(key => {
    return `${prefix}_${key}=s"${typeList[key]}"`
  })

  return tablesList
}

function printTable(tablesList) {
  tablesList.forEach(table => console.log(table))

  console.log('\n')
}

printTable(generateTable('item', itemsList))
printTable(generateTable('mob', monstersList))
