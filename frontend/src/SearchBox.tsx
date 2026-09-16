import { useEffect, useState } from 'react'

// Exported so App (and later the comparison view) can share this shape.
export type Fighter = {
  id: number
  name: string
  nickname: string | null
  wins: number | null
  losses: number | null
  draws: number | null
}

// The inputs this component accepts from its parent.
type SearchBoxProps = {
  label: string
  onSelect: (fighter: Fighter) => void
}

function SearchBox({ label, onSelect }: SearchBoxProps) {
  const [query, setQuery] = useState('')
  const [results, setResults] = useState<Fighter[]>([])

  useEffect(() => {
    if (query.length < 3) {
      setResults([])
      return
    }

    async function search() {
      const url = `http://localhost:8000/fighters/search?q=${encodeURIComponent(query)}`
      const response = await fetch(url)
      const fighters: Fighter[] = await response.json()
      setResults(fighters)
    }

    // debounce: wait 300ms after the last keystroke, then search.
    const timer = setTimeout(search, 300)
    return () => clearTimeout(timer)
  }, [query])

  return (
    <div className="flex flex-col gap-2 w-96">
      <label className="font-semibold">{label}</label>

      <input
        type="text"
        value={query}
        onChange={(e) => setQuery(e.target.value)}
        placeholder="Search a fighter..."
        className="border rounded px-3 py-2"
      />

      <ul className="flex flex-col gap-2">
        {results.map((fighter) => (
          <li
            key={fighter.id}
            onClick={() => {
              onSelect(fighter) // event UP: tell the parent which fighter was picked
              setQuery('') // collapse the dropdown after picking
            }}
            className="flex items-center justify-between rounded-lg border border-gray-200 px-4 py-3 cursor-pointer transition-colors hover:bg-gray-50 hover:border-gray-300"
          >
            <div className="flex flex-col">
              <span className="font-semibold">{fighter.name}</span>
              {fighter.nickname && (
                <span className="text-sm text-gray-500">"{fighter.nickname}"</span>
              )}
            </div>
            {fighter.wins != null && (
              <span className="text-sm text-gray-600 tabular-nums">
                {fighter.wins}-{fighter.losses}-{fighter.draws}
              </span>
            )}
          </li>
        ))}
      </ul>
    </div>
  )
}

export default SearchBox
