module eigenvalue_driver {
    use settings;
    use chunks;
    use Math;
    use profile;
    param MY_MAX_REAL = 1e308;
    param MY_MIN_REAL = -2e308;
    // Calculates the eigenvalues from cg_alphas and cg_betas
    proc eigenvalue_driver_initialise(ref chunk_var : chunks.Chunk, const ref setting_var : settings.setting, 
                                        const ref num_cg_iters: int){
        //chunks per rank for loop
        // profiler.startTimer("eigenvalue_driver_initialise");
        var diag : [0..<num_cg_iters] real;
        var offdiag : [0..<num_cg_iters] real;

         // Prepare matrix
         foreach ii in 0..<num_cg_iters do {
            diag[ii] = 1.0 / chunk_var.cg_alphas[ii];

            if ii > 0 then 
                 diag[ii] += chunk_var.cg_betas[ii-1] / chunk_var.cg_alphas[ii-1];
            if(ii < num_cg_iters-1) then
                offdiag[ii+1] = sqrt(chunk_var.cg_betas[ii]) / chunk_var.cg_alphas[ii];
         }

        // Calculate the eigenvalues (ignore eigenvectors)
        tqli(diag, offdiag, num_cg_iters);

        chunk_var.eigmin = MY_MAX_REAL; // some large positive number
        chunk_var.eigmax = MY_MIN_REAL; // some large negative number

        // Get minimum and maximum eigenvalues
        for ii in 0..<num_cg_iters do {
            chunk_var.eigmin = min(chunk_var.eigmin, diag[ii]);
            chunk_var.eigmax = max(chunk_var.eigmax, diag[ii]);
        }

        if(chunk_var.eigmin < 0.0 || chunk_var.eigmax < 0.0)
        {
            writeln("ERROR: Calculated negative eigenvalues.\n");
            exit(-1);
        }

        chunk_var.eigmin *= 0.95;
        chunk_var.eigmax *= 1.05;

        // profiler.stopTimer("eigenvalue_driver_initialise");
        
        writeln("Min. eigenvalue: ", chunk_var.eigmin);
        writeln("Max. eigenvalue: ", chunk_var.eigmax);
    }
    
    // Function to implement the sign functionality
    inline proc sign(const a: real, const b: real): real {
        if b < 0 then return -abs(a);
        else return abs(a);
    }

    proc tqli (ref d: [0..<n], ref e: [0..<n], const ref n: int){
        
        var m,l,iteration,i : int;
        var s,r,p,g,f,dd,c,b : real;

        for ii in 0..<n-1 do e[ii] = e[ii+1];

        e[n-1]=0.0;
        l = 0;
        for l_prime in 0..<n do {       
            iteration=0;
            do {
                m = l;
                for m_prime in l..<n-1 do{
                    
                    dd=abs(d[m_prime])+abs(d[m_prime+1]);
                    if (abs(e[m_prime])+dd == dd) {
                        break;
                    } 
                    m += 1;
                }
                
                if m == l then break;
                
                iteration += 1;
                if (iteration == 30){
                    writeln ("Too many iterations in TQLI routine");
                    exit(-1);
                }
                
                g=(d[l+1]-d[l])/(2.0*e[l]);
                r=sqrt((g*g)+1.0);
                g=d[m]-d[l]+e[l]/(g+sign(r,g));
                s=1.0;
                c=1.0;
                p=0.0;
                
                var diff : int;
                diff = abs((m-1) - l);
                var ii_prime : int;
                
                for ii in 0..diff {
                    ii_prime = diff - ii;
                    ii_prime = l +  ii_prime;
                    f=s*e[ii_prime];
                    b=c*e[ii_prime];
                    r=sqrt((f*f)+(g*g));
                    e[ii_prime+1]=r;
                    if r == 0.0 {
                        d[ii_prime+1]-=p;
                        e[m]=0.0;
                        continue;
                    }
                    s=f/r;
                    c=g/r;
                    g=d[ii_prime+1]-p;
                    r=(d[ii_prime]-g)*s+2.0*c*b;
                    p=s*r;
                    d[ii_prime+1]=g+p;
                    g=c*r-b;
                }

                d[l]=d[l]-p;
                e[l]=g;
                e[m]=0.0;
            } while (m != l);
            l += 1;
        }
        
    }
}