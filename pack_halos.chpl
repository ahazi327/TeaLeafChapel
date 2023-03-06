module pack_halos{
    use settings;
    use chunks;
    record Kernal {
        var x: int;
        var y: int;
        var depth: int;
        var field: [0..<chunk_var.x*chunk_var.y] real;  // double check size
        var buffer: [0..<chunk_var.x*chunk_var.y] real;
    }
    // Packs left data into buffer.
    proc pack_left (const in x: int, const in y: int, const in depth: int, const in halo_depth: int, inout field : [?F] real, inout buffer: [?B] real){ //could use ref instead of inout
        forall jj in halo_depth..<y-halo_depth do{
            for kk in halo_depth..<halo_depth+depth do{  // possibly could change into one big forall loop with a a specific domain
                var bufIndex: int;
                bufIndex = (kk-halo_depth) + (jj-halo_depth)*depth;
                buffer[bufIndex] = field[jj*x+kk];
            }
        }
    }

    // Packs right data into buffer.
    proc pack_right (const in x: int, const in y: int, const in depth: int, const in halo_depth: int, inout field : [?F] real, inout buffer: [?B] real){
        forall jj in halo_depth..<y-halo_depth do{
            for kk in x-halo_depth..<x-halo_depth do{
                var bufIndex: int;
                bufIndex = (kk-(x-halo_depth-depth)) + (jj-halo_depth)*depth;
                buffer[bufIndex] = field[jj*x+kk];
            }
        }
    }

    // Packs top data into buffer.
    proc pack_top (const in x: int, const in y: int, const in depth: int, const in halo_depth: int, inout field : [?F] real, inout buffer: [?B] real){
        const x_inner : int =  x-2*halo_depth;
        forall jj in y-halo_depth-depth..<y-halo_depth do {
            for kk in halo_depth..<x-halo_depth do{
                var bufIndex: int;
                bufIndex = (kk-halo_depth) + (jj-(y-halo_depth-depth))*x_inner;
                buffer[bufIndex] = field[jj*x+kk];
            }
        }
    }

    // Packs bottom data into buffer.
    proc pack_bottom (const in x: int, const in y: int, const in depth: int, const in halo_depth: int, inout field : [?F] real, inout buffer: [?B] real){
        const x_inner : int =  x-2*halo_depth;
        forall jj in halo_depth..<halo_depth + depth do {
            for kk in halo_depth..<x-halo_depth do{
                var bufIndex: int;
                bufIndex = (kk-halo_depth) + (jj-halo_depth)*x_inner;
                buffer[bufIndex] = field[jj*x+kk];
            }
        }
    }

    // Unpacks left data from buffer.
    proc unpack_left (const in x: int, const in y: int, const in depth: int, const in halo_depth: int, inout field : [?F] real, inout buffer: [?B] real){
        forall jj in halo_depth..<y-halo_depth do{
            for kk in halo_depth-depth..<halo_depth do{
                var bufIndex: int;
                bufIndex = (kk-(halo_depth-depth)) + (jj-halo_depth)*depth;
                field[jj*x+kk] = buffer[bufIndex];
            }
        }
    }

    // Unpacks right data from buffer.
    proc unpack_right (const in x: int, const in y: int, const in depth: int, const in halo_depth: int, inout field : [?F] real, inout buffer: [?B] real){
        forall jj in halo_depth..<y-halo_depth do{
            for kk in x-halo_depth..<x-halo_depth+halo_depth do{
                var bufIndex: int;
                bufIndex = (kk-(x-halo_depth)) + (jj-halo_depth)*depth;
                field[jj*x+kk] = buffer[bufIndex];
            }
        }
    }

    // Unpacks top data from buffer.
    proc unpack_top (const in x: int, const in y: int, const in depth: int, const in halo_depth: int, inout field : [?F] real, inout buffer: [?B] real){
        const x_inner : int =  x-2*halo_depth;
        forall jj in y-halo_depth..<y-halo_depth+depth do{
            for kk in halo_depth..<x-halo_depth do{
                var bufIndex: int;
                bufIndex = (kk-halo_depth) + (jj-(y-halo_depth))*x_inner;
                field[jj*x+kk] = buffer[bufIndex];
            }
        }
    }

    // Unpacks bottom data from buffer.
    proc unpack_bottom (const in x: int, const in y: int, const in depth: int, const in halo_depth: int, inout field : [?F] real, inout buffer: [?B] real){
        const x_inner : int =  x-2*halo_depth;
        forall jj in halo_depth-depth..<halo_depth do{
            for kk in halo_depth..<x-halo_depth do{
                var bufIndex: int;
                bufIndex = (kk-halo_depth) + (jj-(halo_depth-depth))*x_inner;
                field[jj*x+kk] = buffer[bufIndex];
            }
        }
    }

    // Either packs or unpacks data from/to buffers.
    proc pack_or_unpack (const in x: int, const in y: int, const in depth: int, const in halo_depth: int, const in face: int, const in pack: bool,
     inout field : [?F] real, inout buffer: [?B] real, out kernal: Kernal){
        //TODO implement 'die'
        // maybe move kernal structure somewhere else
        var kernal: Kernal;
        kernal = new Kernal();
        kernal.x = x;
        kernal.y = y;
        kernal.depth = depth;
        kernal.halo_depth = halo_depth;

        if face == CHUNK_LEFT & pack {
            pack_left(x, y, depth, halo_depth, field, buffer);
            kernal.field = field;  // probably do not need field array when packing and buffer when unpacking
            kernal.buffer = buffer;
        }
        else if face == CHUNK_LEFT & !pack {
            unpack_left(x, y, depth, halo_depth, field, buffer);
            kernal.field = field;  // probably do not need field array when packing and buffer when unpacking
            kernal.buffer = buffer;
        }

        if face == CHUNK_RIGHT & pack {
            pack_right(x, y, depth, halo_depth, field, buffer);
            kernal.field = field;  
            kernal.buffer = buffer;
        }else if face == CHUNK_RIGHT & !pack {
            unpack_right(x, y, depth, halo_depth, field, buffer);
            kernal.field = field;  
            kernal.buffer = buffer;
        }

        if face == CHUNK_TOP & pack {
            pack_top(x, y, depth, halo_depth, field, buffer);
            kernal.field = field;  
            kernal.buffer = buffer;
        }else if face == CHUNK_TOP & !pack {
            unpack_top(x, y, depth, halo_depth, field, buffer);
            kernal.field = field;  
            kernal.buffer = buffer;
        }

        if face == CHUNK_BOTTOM & !pack {
            pack_bottom(x, y, depth, halo_depth, field, buffer);
            kernal.field = field;  
            kernal.buffer = buffer;
        }else if face == CHUNK_BOTTOM & !pack {
            unpack_bottom(x, y, depth, halo_depth, field, buffer);
            kernal.field = field;  
            kernal.buffer = buffer;
        }
        // else then ''die'' // add die function

    }
}
    

