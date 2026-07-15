import React, { useState, useEffect, useRef } from 'react'
import './assets/main.css'

interface ConversionFile {
  id: string
  name: string
  path: string
  status: 'pending' | 'converting' | 'done' | 'error'
}

function App(): React.JSX.Element {
  const [files, setFiles] = useState<ConversionFile[]>([])
  const [targetFormat, setTargetFormat] = useState('mp4')
  const [isConverting, setIsConverting] = useState(false)
  const [isDragging, setIsDragging] = useState(false)

  useEffect(() => {
    // Listen for progress updates
    const handleProgress = (_event: any, data: { id: string, status: 'converting' | 'done' | 'error', output?: string }) => {
      setFiles(prev => prev.map(f => f.id === data.id ? { ...f, status: data.status } : f))
    }
    window.electron.ipcRenderer.on('conversion-progress', handleProgress)
    return () => {
      window.electron.ipcRenderer.removeAllListeners('conversion-progress')
    }
  }, [])

  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault()
    setIsDragging(true)
  }

  const handleDragLeave = (e: React.DragEvent) => {
    e.preventDefault()
    setIsDragging(false)
  }

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault()
    setIsDragging(false)
    
    if (e.dataTransfer.files && e.dataTransfer.files.length > 0) {
      const newFiles = Array.from(e.dataTransfer.files).map(file => ({
        id: Math.random().toString(36).substr(2, 9),
        name: file.name,
        path: window.api.getPathForFile(file),
        status: 'pending' as const
      }))
      setFiles(prev => [...prev, ...newFiles])
    }
  }

  const handleSelectFiles = () => {
    const input = document.createElement('input')
    input.type = 'file'
    input.multiple = true
    input.onchange = (e: any) => {
      if (e.target.files && e.target.files.length > 0) {
        const newFiles = Array.from(e.target.files as FileList).map(file => ({
          id: Math.random().toString(36).substr(2, 9),
          name: file.name,
          path: window.api.getPathForFile(file),
          status: 'pending' as const
        }))
        setFiles(prev => [...prev, ...newFiles])
      }
    }
    input.click()
  }

  const startConversion = async () => {
    if (files.length === 0 || isConverting) return
    setIsConverting(true)
    
    const pendingFiles = files.filter(f => f.status === 'pending' || f.status === 'error')
    
    try {
      await window.electron.ipcRenderer.invoke('convert-files', pendingFiles.map(f => ({ id: f.id, path: f.path })), targetFormat)
    } catch (error) {
      console.error(error)
    } finally {
      setIsConverting(false)
    }
  }

  const clearDone = () => {
    setFiles(prev => prev.filter(f => f.status !== 'done'))
  }

  // Window Controls
  const minimizeWindow = () => {
    window.electron.ipcRenderer.send('window-minimize')
  }

  const closeWindow = () => {
    window.electron.ipcRenderer.send('window-close')
  }

  return (
    <>
      {/* ---------------- CUSTOM TITLEBAR ---------------- */}
      <div className="titlebar">
        <div className="titlebar-title">
          <span>// CYBER_CONVERT</span>
        </div>
        <div className="titlebar-controls">
          <button className="win-btn" onClick={minimizeWindow}>_</button>
          <button className="win-btn close" onClick={closeWindow}>X</button>
        </div>
      </div>

      <div className="app-content">
        <main>
          {/* Formato de Saída */}
          <div style={{ marginBottom: '20px' }}>
            <label style={{ display: 'block', marginBottom: '5px', color: 'var(--neon-purple)' }}>OUTPUT_FORMAT:</label>
            <select 
              className="select-retro" 
              value={targetFormat} 
              onChange={(e) => setTargetFormat(e.target.value)}
              disabled={isConverting}
            >
              <option value="mp4">.MP4 (Video)</option>
              <option value="webm">.WEBM (Video Web)</option>
              <option value="mp3">.MP3 (Audio)</option>
              <option value="wav">.WAV (Audio Lossless)</option>
              <option value="gif">.GIF (Animated)</option>
              <option value="png">.PNG (Image)</option>
              <option value="jpg">.JPG (Image)</option>
            </select>
          </div>

          {/* Drag Zone */}
          <div 
            className={`drag-zone ${isDragging ? 'active' : ''}`}
            onDragOver={handleDragOver}
            onDragLeave={handleDragLeave}
            onDrop={handleDrop}
            onClick={handleSelectFiles}
          >
            <p style={{ margin: 0, color: 'var(--neon-cyan)' }}>
              &gt; DRAG & DROP FILES HERE
            </p>
            <p style={{ margin: '10px 0 0 0', fontSize: '16px', color: 'var(--neon-purple)' }}>
              [OR CLICK TO SELECT]
            </p>
          </div>

          {/* Lista de Arquivos */}
          <div style={{ flex: 1, minHeight: '150px', border: '1px solid var(--neon-cyan)', padding: '10px', backgroundColor: 'var(--panel-bg)', overflowY: 'auto', marginBottom: '20px' }}>
            {files.length === 0 ? (
              <div style={{ color: 'var(--neon-purple)', textAlign: 'center', marginTop: '20px' }}>No files pending.</div>
            ) : (
              files.map(file => (
                <div key={file.id} className="file-item">
                  <span className="file-name" title={file.path}>{file.name}</span>
                  <span className="file-status" style={{ 
                    color: file.status === 'done' ? 'var(--neon-cyan)' : 
                           file.status === 'error' ? 'red' : 
                           file.status === 'converting' ? 'var(--neon-purple)' : 'var(--neon-pink)' 
                  }}>
                    {file.status === 'pending' && '[PENDING]'}
                    {file.status === 'converting' && '[LOADING]'}
                    {file.status === 'done' && '[OK]'}
                    {file.status === 'error' && '[FAIL]'}
                  </span>
                </div>
              ))
            )}
          </div>

          {/* Ações */}
          <div style={{ display: 'flex', gap: '10px' }}>
            <button 
              className="cyber-btn pink" 
              style={{ flex: 1 }} 
              onClick={startConversion}
              disabled={isConverting || files.length === 0}
            >
              {isConverting ? '> PROCESSING...' : '> CONVERT_ALL'}
            </button>
            <button 
              className="cyber-btn" 
              onClick={clearDone}
              disabled={isConverting}
            >
              CLEAR_OK
            </button>
          </div>
        </main>
      </div>
    </>
  )
}

export default App
