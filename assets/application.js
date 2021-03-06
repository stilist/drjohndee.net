/**
 * The life and times of Dr John Dee
 * Copyright (C) 2021  Jordan Cole <feedback@drjohndee.net>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published
 * by the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

'use strict'

function prepareDataRecordHints() {
  const links = document.querySelectorAll('.data-entity')
  const activatingEventTypes = [
    'focus',
    'pointerenter',
    'mouseenter',
  ]
  const deactivatingEventTypes = [
    'blur',
    'pointerleave',
    'mouseleave',
  ]

  const handleEvent = (event) => {
    const target = event.target
    const allMatches = document.querySelectorAll(`[data-key='${target.dataset.key}']`)
    const isActivating = activatingEventTypes.includes(event.type)
    for (let element of allMatches) {
      element.classList.toggle('is-highlighted', isActivating)
    }
  }
  const eventTypes = activatingEventTypes.concat(deactivatingEventTypes)
  for (let link of links) {
    for (let eventType of eventTypes) {
      link.addEventListener(eventType, handleEvent, {
        passive: true,
      })
    }
  }
}
prepareDataRecordHints()

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
