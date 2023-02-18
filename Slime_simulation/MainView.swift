import MetalKit

struct Particle{
    var color: SIMD4<Float>
    var position: SIMD2<Float>
    var angle: Float
}

struct CS_UNIFORM
{
    //var time: Float
    //var mouse: simd_float2
    var sensorDistance: Float
    var sensorAngle: Float
    var sensorSize: Int
};

class MainView: MTKView {
    
    @IBOutlet weak var txtDotCount: NSTextField!
    @IBOutlet weak var sldDotCount: NSSlider!
    @IBOutlet weak var updateButton: NSButton!
    
    var uiVisible: Bool! = true
    var updateUIVisibility: Bool! = false
    
    func toggleUI(uiVisible: Bool) {
        sldDotCount.isHidden = uiVisible
        txtDotCount.isHidden = uiVisible
        updateButton.isHidden = uiVisible
        self.uiVisible = !self.uiVisible
    }
    
    var commandQueue: MTLCommandQueue!
    var clearPass: MTLComputePipelineState!
    var drawDotPass: MTLComputePipelineState!
    var blurPass: MTLComputePipelineState!
    
    var particleBuffer: MTLBuffer!
    
    var screenSize: Float {
        return Float(self.bounds.width * NSScreen.main!.backingScaleFactor)
    }
    
    var particleCount: Int = 200000
    var initialComputeUniforms = CS_UNIFORM(sensorDistance: 34.0, sensorAngle: 10.0, sensorSize: 1)

    override func viewDidMoveToWindow() {
        txtDotCount.stringValue = String(particleCount)
        sldDotCount.floatValue = Float(particleCount)
    }
    
    var computeUniformsBuffer: MTLBuffer!
    

    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        
        self.framebufferOnly = false
        
        self.device = MTLCreateSystemDefaultDevice()
        self.preferredFramesPerSecond = 120
        
        self.commandQueue = device?.makeCommandQueue()
        
        let library = device?.makeDefaultLibrary()
        let clearFunc = library?.makeFunction(name: "clear_pass_func")
        let drawDotFunc = library?.makeFunction(name: "draw_dots_func")
        let blurFunc = library?.makeFunction(name: "blur_pass_func")
        
        do {
            clearPass = try device?.makeComputePipelineState(function: clearFunc!)
            drawDotPass = try device?.makeComputePipelineState(function: drawDotFunc!)
            blurPass = try device?.makeComputePipelineState(function: blurFunc!)
        } catch let error as NSError {
            print(error)
        }
        guard let drawable = self.currentDrawable else { return }
        createParticles(h: drawable.texture.height, w: drawable.texture.width)
    }
    
    func createParticles(h: Int, w: Int){
        var particles: [Particle] = []
        for _ in 0..<particleCount{
            let a = Float.random(in: 0...(3.1415*2))
            let c = Int.random(in: 0...1)
            var color = SIMD4<Float>(0 * Float.random(in: 0...1), Float.random(in: 0...1), Float.random(in: 0...1), 1)
            if c > 0 {
                color =  SIMD4<Float>(Float.random(in: 0...1), Float.random(in: 0...1), 0 * Float.random(in: 0.8...1), 1)
            }
            let particle = Particle(
                color: color,
                position: Float.random(in: 0...0*(Float(min(h, w)/2) - 1)) * SIMD2<Float>(cos(a), sin(a)) + SIMD2<Float>(Float(w)/2, Float(h)/2),
                angle: a + 0*Float.random(in: 0...3.1415) - 1 * 3.1415)
            particles.append(particle)
        }
        particleBuffer = device?.makeBuffer(bytes: particles, length: MemoryLayout<Particle>.stride * particleCount, options: .storageModeManaged)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        guard let drawable = self.currentDrawable else { return }
        
        if (updateUIVisibility == true) {
            toggleUI(uiVisible: uiVisible)
            updateUIVisibility = false
        }
        
        let commandbuffer = commandQueue.makeCommandBuffer()
        let computeCommandEncoder = commandbuffer?.makeComputeCommandEncoder()
        
        computeCommandEncoder?.setComputePipelineState(clearPass)
        computeCommandEncoder?.setTexture(drawable.texture, index: 0)
        
        let w = clearPass.threadExecutionWidth
        let h = clearPass.maxTotalThreadsPerThreadgroup / w
        
        // Create our uniform buffer, and fill it with an initial brightness of 1.0
        var initialComputeUniforms = CS_UNIFORM(
            sensorDistance: 6.0,
            sensorAngle: 16.0,
            sensorSize: 1
        )
 
        let computeUniformsBuffer = (device?.makeBuffer(bytes: &initialComputeUniforms, length: MemoryLayout<CS_UNIFORM>.stride, options: [])!)!
        
  
        
        var threadsPerThreadGroup = MTLSize(width: w, height: h, depth: 1)
        var threadsPerGrid = MTLSize(width: drawable.texture.width, height: drawable.texture.height, depth: 1)
        computeCommandEncoder?.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadGroup)

        computeCommandEncoder?.setComputePipelineState(drawDotPass)
        computeCommandEncoder?.setBuffer(particleBuffer, offset: 0, index: 0)

        computeCommandEncoder!.setBuffer(computeUniformsBuffer, offset: 0, index: 1)


        //computeCommandEncoder?.setBuffer(computeUniformsBuffer, offset: 0, index: 0)
        threadsPerGrid = MTLSize(width: particleCount, height: 1, depth: 1)
        threadsPerThreadGroup = MTLSize(width: w, height: 1, depth: 1)
        computeCommandEncoder?.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadGroup)

        computeCommandEncoder?.setComputePipelineState(blurPass)
        computeCommandEncoder!.setBuffer(computeUniformsBuffer, offset: 0, index: 1)

        computeCommandEncoder?.setTexture(drawable.texture, index: 1)
        computeCommandEncoder?.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadGroup)
        

        
        computeCommandEncoder?.endEncoding()
        commandbuffer?.present(drawable)
        commandbuffer?.commit()
    }
    
    @IBAction func sldParticleCountUpdate(_ sender: NSSlider) {
        if (Int(sender.floatValue) > 0) {
            txtDotCount.stringValue = String(Int(sender.floatValue))
        }
    }
    
    @IBAction func btnUpdate(_ sender: NSButton) {
        if (Int(txtDotCount.stringValue)! > 0) {
            particleCount = Int(txtDotCount.stringValue)!
            sldDotCount.floatValue = Float(txtDotCount.stringValue)!
            guard let drawable = self.currentDrawable else { return }
            createParticles(h: drawable.texture.height, w: drawable.texture.width)
        }
    }
    
}
