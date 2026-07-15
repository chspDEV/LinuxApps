import React, { useState, useEffect, useRef } from 'react'
import './assets/main.css'

interface Song {
  name: string
  path: string
}

function App(): React.JSX.Element {
  const [searchUrl, setSearchUrl] = useState('')
  const [isDownloading, setIsDownloading] = useState(false)
  const [songs, setSongs] = useState<Song[]>([])
  const [currentSongIndex, setCurrentSongIndex] = useState<number>(-1)
  const [isPlaying, setIsPlaying] = useState(false)
  
  const audioRef = useRef<HTMLAudioElement | null>(null)

  const fetchSongs = async () => {
    try {
      const list = await window.electron.ipcRenderer.invoke('list-audio')
      setSongs(list)
    } catch (error) {
      console.error('Failed to list audio:', error)
    }
  }

  useEffect(() => {
    fetchSongs()
  }, [])

  const handleDownload = async () => {
    if (!searchUrl) return
    setIsDownloading(true)
    try {
      const result = await window.electron.ipcRenderer.invoke('download-audio', searchUrl)
      if (result.success) {
        setSearchUrl('')
        alert('Download concluído com sucesso!')
        fetchSongs() // Refresh list
      } else {
        alert('Erro no download: ' + result.error)
      }
    } catch (error) {
      console.error(error)
      alert('Erro de comunicação com o sistema.')
    } finally {
      setIsDownloading(false)
    }
  }

  const playSong = (index: number) => {
    if (index >= 0 && index < songs.length) {
      setCurrentSongIndex(index)
      if (audioRef.current) {
        audioRef.current.src = `file://${songs[index].path}`
        audioRef.current.play()
        setIsPlaying(true)
      }
    }
  }

  const togglePlay = () => {
    if (!audioRef.current || currentSongIndex === -1) return
    if (isPlaying) {
      audioRef.current.pause()
      setIsPlaying(false)
    } else {
      audioRef.current.play()
      setIsPlaying(true)
    }
  }

  const playNext = () => {
    playSong((currentSongIndex + 1) % songs.length)
  }

  const playPrev = () => {
    playSong((currentSongIndex - 1 + songs.length) % songs.length)
  }

  return (
    <div className="app-container">
      <header className="nes-container is-dark with-title" style={{ marginTop: '20px' }}>
        <p className="title">Retro Player</p>
        <p>Bem-vindo ao reprodutor definitivo 8-bit.</p>
      </header>

      <main style={{ marginTop: '30px' }}>
        {/* Sessão de Download */}
        <section className="nes-container is-dark">
          <h3 className="nes-text is-primary">Baixar Música</h3>
          <div className="nes-field" style={{ marginBottom: '15px' }}>
            <label htmlFor="url_field">URL do YouTube ou Nome da Música</label>
            <input 
              type="text" 
              id="url_field" 
              className="nes-input is-dark" 
              placeholder="Cole o link ou pesquise..."
              value={searchUrl}
              onChange={(e) => setSearchUrl(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && !isDownloading && handleDownload()}
            />
          </div>
          <button 
            type="button" 
            className={`nes-btn ${isDownloading ? 'is-disabled' : 'is-success'}`}
            onClick={handleDownload}
            disabled={isDownloading}
          >
            {isDownloading ? 'Baixando...' : 'Download'}
          </button>
          
          {isDownloading && (
            <progress className="nes-progress is-primary" value="50" max="100" style={{ marginTop: '15px' }}></progress>
          )}
        </section>

        {/* Player Section */}
        <section className="nes-container is-dark" style={{ marginTop: '30px' }}>
          <h3 className="nes-text is-warning">Minhas Músicas</h3>
          <div className="nes-table-responsive" style={{ maxHeight: '200px', overflowY: 'auto' }}>
            <table className="nes-table is-bordered is-dark" style={{ width: '100%' }}>
              <thead>
                <tr>
                  <th>#</th>
                  <th>Faixa</th>
                </tr>
              </thead>
              <tbody>
                {songs.length === 0 ? (
                  <tr>
                    <td colSpan={2} style={{ textAlign: 'center' }}>Nenhuma música encontrada.</td>
                  </tr>
                ) : (
                  songs.map((song, index) => (
                    <tr 
                      key={index} 
                      onClick={() => playSong(index)}
                      style={{ 
                        cursor: 'pointer', 
                        backgroundColor: currentSongIndex === index ? '#209cee' : 'transparent',
                        color: currentSongIndex === index ? '#000' : '#fff'
                      }}
                    >
                      <td>{index + 1}</td>
                      <td>{song.name.replace('.mp3', '')}</td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>

          <div style={{ marginTop: '20px', display: 'flex', gap: '10px', alignItems: 'center', justifyContent: 'center' }}>
            <button type="button" className="nes-btn is-primary" onClick={playPrev} disabled={songs.length === 0}>⏮</button>
            <button type="button" className={`nes-btn ${isPlaying ? 'is-error' : 'is-success'}`} onClick={togglePlay} disabled={songs.length === 0}>
              {isPlaying ? '⏸ Pause' : '▶ Play'}
            </button>
            <button type="button" className="nes-btn is-primary" onClick={playNext} disabled={songs.length === 0}>⏭</button>
          </div>

          {/* Hidden Audio Element */}
          <audio ref={audioRef} onEnded={playNext} />
        </section>
      </main>
    </div>
  )
}

export default App
