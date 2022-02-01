class Item {
  constructor(name, type, stat1, stat2, minf, maxf) {
    this.name = name
    this.type = type
    this.stat1 = stat1
    this.stat2 = stat2
    this.minf = minf
    this.maxf = maxf
  }
}

class Monster {
  constructor(name, sprs, atk, hp, los, minf, maxf) {
    this.name = name
    this.sprs = sprs
    this.atk = atk
    this.hp = hp
    this.los = los
    this.minf = minf
    this.maxf = maxf
  }
}

const itemsList = [
  new Item('butter knife', 'wep', 1, 0, 1, 3),
  new Item('cheese knife', 'wep', 2, 0, 2, 4),
  new Item('paring knife', 'wep', 3, 0, 3, 5),
  new Item('utility knife', 'wep', 4, 0, 4, 6),
  new Item('chef\'s knife', 'wep', 5, 0, 5, 7),
  new Item('meat cleaver', 'wep', 6, 0, 6, 8),
  new Item('leather armor', 'arm', 0, 2, 1, 8),
  new Item('red bean paste', 'fud', 1, 0, 1, 8),
  new Item('ninja star', 'thr', 1, 0, 1, 8),
  new Item('rusty sword', 'wep', 1, 0, 1, 8)
]

const monstersList = [
  new Monster('player', 240, 1, 5, 4, 1, 10),
  new Monster('slime', 192, 1, 1, 4, 1, 3)
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

function printTable(title, tablesList) {
  console.log(title + '\n')

  tablesList.forEach(table => console.log(table))

  console.log('---\n')
}

printTable('Items', generateTable('item', itemsList))
printTable('Monsters', generateTable('mob', monstersList))
