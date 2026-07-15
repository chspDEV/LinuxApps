import React, { useState, useEffect, useRef } from 'react'
import './assets/main.css'

interface Song {
  name: string
  path: string
  cover?: string
}

const getSafeFileUrl = (filePath: string) => {
  if (!filePath) return ''
  return `asset://${encodeURIComponent(filePath).replace(/%2F/g, '/')}`
}

function App(): React.JSX.Element {
  const [searchUrl, setSearchUrl] = useState('')
  const [isDownloading, setIsDownloading] = useState(false)
  const [songs, setSongs] = useState<Song[]>([])
  const [currentSongIndex, setCurrentSongIndex] = useState<number>(-1)
  const [isPlaying, setIsPlaying] = useState(false)
  
  // Navigation State
  const [currentView, setCurrentView] = useState<'library' | 'player'>('library')
  
  // Audio Time State
  const [currentTime, setCurrentTime] = useState(0)
  const [duration, setDuration] = useState(0)
  
  // Volume State
  const [volume, setVolume] = useState(1)

  const audioRef = useRef<HTMLAudioElement | null>(null)

  useEffect(() => {
    if (audioRef.current) {
      audioRef.current.volume = volume
    }
  }, [volume])

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
        fetchSongs() // Refresh list
      } else {
        alert('Erro: ' + result.error)
      }
    } catch (error) {
      console.error(error)
    } finally {
      setIsDownloading(false)
    }
  }

  const playSong = (index: number) => {
    if (index >= 0 && index < songs.length) {
      setCurrentSongIndex(index)
      if (audioRef.current) {
        audioRef.current.src = getSafeFileUrl(songs[index].path)
        audioRef.current.play()
        setIsPlaying(true)
        setCurrentView('player') 
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
    if (songs.length === 0) return
    playSong((currentSongIndex + 1) % songs.length)
  }

  const playPrev = () => {
    if (songs.length === 0) return
    playSong((currentSongIndex - 1 + songs.length) % songs.length)
  }

  const handleTimeUpdate = () => {
    if (audioRef.current) setCurrentTime(audioRef.current.currentTime)
  }

  const handleLoadedMetadata = () => {
    if (audioRef.current) setDuration(audioRef.current.duration)
  }
  
  const formatTime = (timeInSeconds: number) => {
    if (isNaN(timeInSeconds)) return "0:00"
    const m = Math.floor(timeInSeconds / 60)
    const s = Math.floor(timeInSeconds % 60)
    return `${m}:${s < 10 ? '0' : ''}${s}`
  }

  // Window Controls
  const minimizeWindow = () => {
    window.electron.ipcRenderer.send('window-minimize')
  }

  const closeWindow = () => {
    window.electron.ipcRenderer.send('window-close')
  }

  const asciiPlayer = `
   ▄████████ 
  ███    ███ 
  ███    █▀  
 ▄███▄▄▄     
▀▀███▀▀▀     
  ███        
  ███        
  ███        
  `

  return (
    <>
      {/* ---------------- CUSTOM TITLEBAR ---------------- */}
      <div className="titlebar">
        <div className="titlebar-title">
          <span>// CYBER_PLAYER</span>
        </div>
        <div className="titlebar-controls">
          <button className="win-btn" onClick={minimizeWindow}>_</button>
          <button className="win-btn close" onClick={closeWindow}>X</button>
        </div>
      </div>

      <div className="app-content">
        
        {/* ---------------- TELA 1: BIBLIOTECA ---------------- */}
        {currentView === 'library' && (
          <main>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '15px' }}>
              <span style={{ color: 'var(--neon-pink)', fontSize: '24px' }}>/home/music</span>
              {currentSongIndex !== -1 && (
                <button className="cyber-btn pink" onClick={() => setCurrentView('player')} style={{ fontSize: '16px' }}>
                  [TOCANDO]
                </button>
              )}
            </div>

            <section className="nes-container is-dark with-title" style={{ padding: '10px' }}>
              <p className="title">GET_AUDIO</p>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
                <input 
                  type="text" 
                  className="nes-input is-dark" 
                  placeholder="URL YouTube..."
                  value={searchUrl}
                  onChange={(e) => setSearchUrl(e.target.value)}
                  onKeyDown={(e) => e.key === 'Enter' && !isDownloading && handleDownload()}
                />
                <button 
                  type="button" 
                  className="cyber-btn"
                  onClick={handleDownload}
                  disabled={isDownloading}
                  style={{ width: '100%' }}
                >
                  {isDownloading ? '> DOWNLOADING...' : '> DOWNLOAD'}
                </button>
              </div>
              {isDownloading && (
                <progress className="nes-progress is-primary" value="50" max="100" style={{ marginTop: '10px' }}></progress>
              )}
            </section>

            <div style={{ marginTop: '20px' }}>
              <p style={{ color: 'var(--neon-purple)', marginBottom: '10px' }}>ls -l *.mp3</p>
              <div style={{ maxHeight: '240px', overflowY: 'auto', border: '1px solid var(--neon-purple)', padding: '5px' }}>
                {songs.length === 0 ? (
                  <div style={{ padding: '10px', textAlign: 'center', color: 'var(--neon-purple)' }}>No files found.</div>
                ) : (
                  songs.map((song, index) => (
                    <div 
                      key={index}
                      className={`song-list-item ${currentSongIndex === index ? 'active' : ''}`}
                      onClick={() => playSong(index)}
                    >
                      <span style={{ color: 'var(--neon-purple)' }}>
                        {index === currentSongIndex && isPlaying ? '>' : '-'}
                      </span>
                      <span style={{ whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                        {song.name.replace('.mp3', '')}
                      </span>
                    </div>
                  ))
                )}
              </div>
            </div>
          </main>
        )}

        {/* ---------------- TELA 2: PLAYER COMPLETO ---------------- */}
        {currentView === 'player' && (
          <main style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
            
            <div style={{ marginBottom: '15px' }}>
              <button className="cyber-btn" onClick={() => setCurrentView('library')} style={{ fontSize: '16px' }}>
                &lt; BACK
              </button>
            </div>

            <div style={{ 
              flex: 1,
              display: 'flex', 
              flexDirection: 'column', 
              alignItems: 'center', 
              justifyContent: 'center',
              border: '1px solid var(--neon-cyan)',
              padding: '20px',
              backgroundColor: 'var(--panel-bg)',
              boxShadow: 'inset 0 0 20px rgba(1, 205, 254, 0.1)'
            }}>
              
              <div className="ascii-art" style={{ width: '100%', display: 'flex', justifyContent: 'center', alignItems: 'center', height: '200px' }}>
                {songs[currentSongIndex]?.cover ? (
                  <img 
                    src={getSafeFileUrl(songs[currentSongIndex].cover!)} 
                    alt="cover" 
                    style={{ maxWidth: '100%', maxHeight: '100%', objectFit: 'cover', border: '1px solid var(--neon-pink)', boxShadow: '0 0 15px rgba(255,113,206,0.3)' }} 
                  />
                ) : (
                  asciiPlayer
                )}
              </div>

              <div style={{ 
                textAlign: 'center', 
                marginBottom: '30px', 
                width: '100%',
                borderBottom: '1px solid var(--neon-pink)',
                paddingBottom: '10px'
              }}>
                <div style={{ color: 'var(--neon-pink)', fontSize: '22px', overflow: 'hidden', whiteSpace: 'nowrap', textOverflow: 'ellipsis' }}>
                  {songs[currentSongIndex]?.name.replace('.mp3', '') || 'NO_AUDIO_TRACK_SELECTED'}
                </div>
              </div>

              {/* Barra de Progresso */}
              <div style={{ width: '100%', marginBottom: '30px' }}>
                <progress 
                  className="nes-progress is-primary" 
                  value={currentTime} 
                  max={duration || 100} 
                ></progress>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '16px', marginTop: '8px', color: 'var(--neon-cyan)' }}>
                  <span>{formatTime(currentTime)}</span>
                  <span>{formatTime(duration)}</span>
                </div>
              </div>

              {/* Controles de Playback */}
              <div style={{ display: 'flex', gap: '15px', alignItems: 'center', justifyContent: 'center', width: '100%' }}>
                <button type="button" className="cyber-btn" onClick={playPrev} disabled={songs.length === 0}>|&lt;</button>
                <button 
                  type="button" 
                  className={`cyber-btn ${isPlaying ? 'pink' : ''}`}
                  onClick={togglePlay} 
                  disabled={songs.length === 0}
                  style={{ padding: '10px 25px' }}
                >
                  {isPlaying ? 'PAUSE' : 'PLAY'}
                </button>
                <button type="button" className="cyber-btn" onClick={playNext} disabled={songs.length === 0}>&gt;|</button>
              </div>

              {/* Controle de Volume */}
              <div style={{ marginTop: '20px', display: 'flex', alignItems: 'center', gap: '10px', width: '100%', color: 'var(--neon-purple)' }}>
                <span>VOL:</span>
                <input 
                  type="range" 
                  min="0" 
                  max="1" 
                  step="0.05"
                  value={volume}
                  onChange={(e) => setVolume(Number(e.target.value))}
                  style={{ flex: 1, accentColor: 'var(--neon-pink)' }}
                />
              </div>
            </div>

          </main>
        )}

        {/* Hidden Audio Element */}
        <audio 
          ref={audioRef} 
          onEnded={playNext} 
          onTimeUpdate={handleTimeUpdate}
          onLoadedMetadata={handleLoadedMetadata}
        />
      </div>
    </>
  )
}

export default App
