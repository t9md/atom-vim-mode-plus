module.exports = class ScrollManager {
  constructor (vimState) {
    this.vimState = vimState
    vimState.onDidDestroy(() => this.destroy())
  }

  destroy () {
    this.scrollRequest = null
  }

  // It's possible that multiple scroll request comes in sequentially.
  //
  // When you pass `amountOfPixels`, it calculate final scrollTop based on
  // prevoiusly requested scrollTop. In other word. animation is concatnated to
  // scroll smoothly in sequential request.
  //
  // When you pass `scrollTop`, it's absolute value, just use passed scrollTop.
  // So passed scrollTop should not be based on **relative** scrollTop, because it's might not finalized.
  // - OK: {scrollTop: cursor.pixelPositionForScreenPosition(point) + pixels}
  // - NG: {scrollTop: editorElement.getScrollTop() + pixels}
  // - Hacky but should be OK: {scrollTop: vimState.scrollRequest.scrollTop + pixels}
  requestScroll ({amountOfPixels, scrollTop, duration, onFinish}) {
    const {editorElement} = this.vimState
    const currentScrollTop = editorElement.getScrollTop()
    let baseScrollTop = currentScrollTop

    if (this.scrollRequest) {
      this.scrollRequest.cancel()
      baseScrollTop = this.scrollRequest.scrollTop
      this.scrollRequest = null
    }

    if (amountOfPixels) {
      scrollTop = baseScrollTop + amountOfPixels
    }

    if (!duration) {
      editorElement.setScrollTop(scrollTop)
      if (onFinish) onFinish()
      return
    }

    const deltaInPixels = scrollTop - currentScrollTop
    const cancel = animateInDuration(duration, progress => {
      if (editorElement.component) {
        // [NOTE]
        // intentionally use `element.component.setScrollTop` instead of `element.setScrollTop`.
        // Since element.setScrollTop will throw exception when element.component no longer exists.
        editorElement.component.setScrollTop(currentScrollTop + deltaInPixels * progress)
        editorElement.component.updateSync()
      }
      if (progress === 1) {
        this.scrollRequest = null
        if (onFinish) onFinish()
      }
    })

    this.scrollRequest = {scrollTop, cancel}
  }
}

function animateInDuration (msec, fn) {
  let startTime, nextRequestID

  function step (timestamp) {
    if (!startTime) startTime = timestamp
    const progress = Math.min((timestamp - startTime) / msec, 1)
    if (progress < 1) {
      nextRequestID = window.requestAnimationFrame(step)
    }
    fn(progress)
  }
  nextRequestID = window.requestAnimationFrame(step)

  return () => {
    window.cancelAnimationFrame(nextRequestID)
  }
}
