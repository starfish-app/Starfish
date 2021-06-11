public class Starfish.Core.TextBody : Object {

    public Mime mime { get; private set; }

    private IOStream connection;
    private DataInputStream body;

    public bool is_done { get { return connection.is_closed (); } }

    public TextBody.from_string (owned string content) {
        var mime = new Mime ("text/plain");
        var memory_stream = new MemoryInputStream.from_data(content.data);
        var data_stream = new DataInputStream (memory_stream);
        var in_mem_out = new MemoryOutputStream.resizable ();
        var in_mem_conn = new SimpleIOStream (data_stream, in_mem_out);
        this (mime, in_mem_conn);
    }

    public TextBody (Mime mime, owned IOStream connection) {
        this.connection = connection;
        var in_stream = connection.input_stream;
        if (mime.charset != "utf-8") {
            try {
                var converter = new CharsetConverter ("utf-8", mime.charset);
                in_stream = new ConverterInputStream (in_stream, converter);
            } catch (Error e) {
                warning ("Could not create CharsetConverter for %s, input might be missread! Error: %s", mime.charset, e.message);
            }
        }

        this.body = new DataInputStream (in_stream) {
            newline_type = DataStreamNewlineType.ANY,
            close_base_stream = true
        };

        this.mime = mime;
    }

    public void close () {
        try_to_close_connection.begin ();
    }

    public async void foreach_line (OnNextLine on_next, Cancellable cancel) {
        Line? line = null;
        do {
            line = yield read_line (cancel);
            if (line != null) {
                on_next (line);
            }
            Idle.add(foreach_line.callback);
            yield;
        } while (line != null && !cancel.is_cancelled ());
        yield try_to_close_connection ();
    }

    private async Line? read_line (Cancellable cancel) {
        if (is_done) {
            return null;
        }

        try {
            var row = yield body.read_line_utf8_async (Priority.HIGH, cancel);
            if (row == null) {
                yield try_to_close_connection ();
                return null;
            }

            return new Line (row, guess_type (row));
        } catch (Error e) {
            yield try_to_close_connection ();
            if (body.get_available() > 0) {
                return yield try_to_read_the_final_line (cancel);
            }

            return null;
        }
    }

    protected virtual LineType guess_type (string row) {
        return LineType.TEXT;
    }

    private async void try_to_close_connection () {
        try {
            yield connection.close_async (Priority.DEFAULT);
        } catch (IOError e) {
            warning ("Could not close connection, might leak resources! Error: %s", e.message);
        }
    }

    private async Line? try_to_read_the_final_line (Cancellable cancel) {
        try {
            var buff = new uint8[body.get_available ()];
            size_t read;
            yield body.read_all_async (buff, Priority.HIGH, cancel, out read);
            var builder = new StringBuilder ();
            foreach (var c in buff) {
                builder.append_c ((char) c);
            }

            var row = builder.str;
            return new Line (row, guess_type (row));
        } catch (Error e) {
            warning ("Failed to read the final line. Page might be incomplete. Error: %s", e.message);
            return null;
        }
    }
}

public delegate void Starfish.Core.OnNextLine (Line line);

