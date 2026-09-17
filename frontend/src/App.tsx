import { useEffect, useState } from 'react'
import SearchBox, { type Fighter } from './SearchBox'
import { API_BASE } from './config'

// The 8 career stats we compare, in display order + labels. Direction (e.g.
// sapm is "lower is better") is decided by the backend, so the frontend never
// judges winners itself — it just trusts the verdict the API sends back.
type StatKey =
  | 'slpm'
  | 'str_acc'
  | 'sapm'
  | 'str_def'
  | 'td_avg'
  | 'td_acc'
  | 'td_def'
  | 'sub_avg'

const STATS: { key: StatKey; label: string; suffix?: string }[] = [
  { key: 'slpm', label: 'Sig. strikes landed / min' },
  { key: 'str_acc', label: 'Striking accuracy', suffix: '%' },
  { key: 'sapm', label: 'Sig. strikes absorbed / min' },
  { key: 'str_def', label: 'Striking defense', suffix: '%' },
  { key: 'td_avg', label: 'Takedowns / 15 min' },
  { key: 'td_acc', label: 'Takedown accuracy', suffix: '%' },
  { key: 'td_def', label: 'Takedown defense', suffix: '%' },
  { key: 'sub_avg', label: 'Submission attempts / 15 min' },
]

// The shape /fighters/compare returns.
type Verdict = 'a' | 'b' | 'draw' | null
type ComparedFighter = Fighter & Record<StatKey, number | null>
type Comparison = {
  a: ComparedFighter
  b: ComparedFighter
  comparison: Record<StatKey, Verdict>
}

// One fighter's value styling for a stat: bold green if this side won,
// neutral on a draw, greyed if it lost or the stat can't be compared.
function cellClass(verdict: Verdict, side: 'a' | 'b'): string {
  if (verdict === side) return 'font-bold text-emerald-600'
  if (verdict === 'draw') return 'text-gray-700'
  return 'text-gray-400'
}

function formatStat(value: number | null, suffix = ''): string {
  return value == null ? '—' : `${value}${suffix}`
}

function App() {
  const [fighterA, setFighterA] = useState<Fighter | null>(null)
  const [fighterB, setFighterB] = useState<Fighter | null>(null)
  const [comparison, setComparison] = useState<Comparison | null>(null)

  useEffect(() => {
    // need BOTH fighters to compare; clear any stale result until then
    if (!fighterA || !fighterB) {
      setComparison(null)
      return
    }

    async function compare() {
      const url = `${API_BASE}/fighters/compare?a=${fighterA!.id}&b=${fighterB!.id}`
      const response = await fetch(url)
      const data: Comparison = await response.json()
      setComparison(data)
    }

    compare()
  }, [fighterA, fighterB])

  return (
    <main className="min-h-screen flex flex-col items-center gap-8 pt-16">
      <h1 className="text-3xl font-bold">UFC Fighter Comparison</h1>

      <div className="flex gap-8">
        <SearchBox label="Fighter A" onSelect={setFighterA} />
        <SearchBox label="Fighter B" onSelect={setFighterB} />
      </div>

      {/* width matches the boxes above (w-96 + gap-8 + w-96 = 800px); flex-1 on
          each name claims an equal half so "vs" stays pinned dead-center */}
      <div className="flex w-[800px] items-center text-xl font-semibold">
        <span className="flex-1 text-center">{fighterA?.name ?? '—'}</span>
        <span className="px-4 text-gray-400">vs</span>
        <span className="flex-1 text-center">{fighterB?.name ?? '—'}</span>
      </div>

      {comparison && (
        <div className="flex w-[800px] flex-col">
          {STATS.map(({ key, label, suffix }) => {
            const verdict = comparison.comparison[key]
            return (
              <div
                key={key}
                className="grid grid-cols-[1fr_auto_1fr] items-center gap-4 border-b border-gray-100 py-2"
              >
                <span className={`text-right tabular-nums ${cellClass(verdict, 'a')}`}>
                  {formatStat(comparison.a[key], suffix)}
                </span>
                <span className="w-56 text-center text-sm text-gray-500">{label}</span>
                <span className={`text-left tabular-nums ${cellClass(verdict, 'b')}`}>
                  {formatStat(comparison.b[key], suffix)}
                </span>
              </div>
            )
          })}
        </div>
      )}
    </main>
  )
}

export default App
