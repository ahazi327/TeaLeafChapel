module pack_halos{
    use settings;
    use chunks;
    var BigDomain = {0..<chunk_var.x, 0..<chunk_var.y};
    record Kernal {
        var x: int;
        var y: int;
        var depth: int;
        var field: [BigDomain] real;  // double check size
        var buffer: [BigDomain] real;
    }
    // Packs left data into buffer.
    proc pack_left (const in x: int, const in y: int, const in depth: int, const in halo_depth: int, inout field : [?F] real, inout buffer: [?B] real){ //could use ref instead of inout
        const inner_domain = BigDomain[halo_depth..<halo_depth+depth, halo_depth..<y-halo_depth];
        forall (kk, jj) in inner_domain do{
            buffer[kk, jj] = field[kk + halo_depth, jj];  // using own calculations as c code seems to be convoluted and redundent with pack right code, but come back and check alter is having issues
        }
    }

    // Packs right data into buffer.
    proc pack_right (const in x: int, const in y: int, const in depth: int, const in halo_depth: int, inout field : [?F] real, inout buffer: [?B] real){
        const inner_domain = BigDomain[halo_depth..<halo_depth+depth, halo_depth..<y-halo_depth];
        forall (kk, jj) in inner_domain do{
            buffer[kk, jj] = field[kk - halo_depth, jj];  // maybe change halo depth to just 1
        }
    }

    // Packs top data into buffer.
    proc pack_top (const in x: int, const in y: int, const in depth: int, const in halo_depth: int, ref field : [?F] real, ref buffer: [?B] real){
        const inner_domain = BigDomain[halo_depth..<halo_depth+depth, halo_depth..<y-halo_depth];
        forall (kk, jj) in inner_domain do{
            buffer[kk, jj] = field[kk, jj - halo_depth];
        }
    }

    // Packs bottom data into buffer.
    proc pack_bottom (const in x: int, const in y: int, const in depth: int, const in halo_depth: int, ref field : [?F] real, ref buffer: [?B] real){
        const inner_domain = BigDomain[halo_depth..<halo_depth+depth, halo_depth..<y-halo_depth];
        forall (kk, jj) in inner_domain do{
            buffer[kk, jj] = field[kk, jj + halo_depth];
        }
    }

    // Unpacks left data from buffer.
    proc unpack_left (const in x: int, const in y: int, const in depth: int, const in halo_depth: int, ref field : [?F] real, ref buffer: [?B] real){
        const inner_domain = BigDomain[halo_depth..<halo_depth+depth, halo_depth..<y-halo_depth];
        forall (kk, jj) in inner_domain do{
            field[kk, jj] = buffer[kk + halo_depth, jj];
        }
    }

    // Unpacks right data from buffer.
    proc unpack_right (const in x: int, const in y: int, const in depth: int, const in halo_depth: int, ref field : [?F] real, ref buffer: [?B] real){
        const inner_domain = {halo_depth..<y-halo_depth, x-halo_depth..<x-halo_depth+halo_depth};
        forall (jj, kk) in inner_domain do{
            field[kk, jj] = buffer[kk - halo_depth, jj]; 
        }
    }

    // Unpacks top data from buffer.
    proc unpack_top (const in x: int, const in y: int, const in depth: int, const in halo_depth: int, ref field : [?F] real, ref buffer: [?B] real){
        const inner_domain = {y-halo_depth..<y-halo_depth+depth, halo_depth..<x-halo_depth};
        forall (jj, kk) in inner_domain do{
            field[kk, jj] = buffer[kk, jj - halo_depth];
        }
    }

    // Unpacks bottom data from buffer.
    proc unpack_bottom (const in x: int, const in y: int, const in depth: int, const in halo_depth: int, ref field : [?F] real, ref buffer: [?B] real){
        const inner_domain = {halo_depth-depth..<halo_depth, halo_depth..<x-halo_depth};
        forall (kk, jj) in inner_domain do{
            field[kk, jj] = buffer[kk, jj + halo_depth];
        }
    }

    // Either packs or unpacks data from/to buffers.
    proc pack_or_unpack (const in x: int, const in y: int, const in depth: int, const in halo_depth: int, const in face: int, const in pack: bool,
     ref field : [?F] real, ref buffer: [?B] real, out kernal: Kernal){
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
            kernal.field = field;  
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
    

