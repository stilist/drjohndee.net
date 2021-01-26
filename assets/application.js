'use strict';

if (document.body.classList.contains('debug')) {
  const nRows = 500
  const nColumns = 20

  const grid = document.createElement('div')
  grid.id = 'scale'
  for (let i = 0; i < nRows; i++) {
    const row = document.createElement('div')
    row.className = 'row'
    for (let j = 0; j < nColumns; j++) {
      const cell = document.createElement('span')
      row.appendChild(cell)
    }
    grid.appendChild(row)
  }
  const fragment = new DocumentFragment()
  fragment.appendChild(grid)
  document.body.appendChild(fragment)
}
