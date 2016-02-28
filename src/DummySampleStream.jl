type DummySampleSource{N, SR, T <: Real} <: SampleSource{N, SR, T}
    buf::Array{T, 2}
    DummySampleSource() = new(Array(T, (0, N)))
end

DummySampleSource(T, SR, N) = DummySampleSource{N, SR, T}()

type DummySampleSink{N, SR, T <: Real} <: SampleSink{N, SR, T}
    buf::Array{T, 2}
    DummySampleSink() = new(Array(T, (0, N)))
end

DummySampleSink(T, SR, N) = DummySampleSink{N, SR, T}()

"""
Simulate receiving input on the dummy source This adds data to the internal
buffer, so that when client code reads from the source they receive this data.
"""
function simulate_input{N, SR, T}(src::DummySampleSource{N, SR, T}, data::Array{T})
    if size(data, 2) != N
        error("Simulated data channel count must match stream input count")
    end
    src.buf = vcat(src.buf, data)
end

# stream interface methods

"""
Writes the sample buffer to the sample sink. If no other writes have been
queued the Sample will be played immediately. If a previously-written buffer is
in progress the signal will be queued. To mix multiple signal see the `play`
function. Currently we only implement the non-resampling, non-converting method.
"""
function Base.write{N, SR, T}(sink::DummySampleSink{N, SR, T}, buf::TimeSampleBuf{N, SR, T})
    # TODO: probably should check channels here instead of using dispatch so we can give a better error message
    sink.buf = vcat(sink.buf, buf.data)

    nframes(buf)
end

"""
Fills the given buffer with the data from the stream. If there aren't enough
frames in the stream then it's considered to be at its end and will only
partally fill the buffer.
"""
function Base.read!{N, SR, T}(src::DummySampleSource{N, SR, T}, buf::TimeSampleBuf{N, SR, T})
    n = min(nframes(buf), size(src.buf, 1))
    buf.data[1:n, :] = src.buf[1:n, :]
    src.buf = src.buf[(n+1):end, :]

    n
end
