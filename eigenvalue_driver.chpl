module eigenvalue_driver {
    use settings;
    use chunks;
    param MY_MAX_REAL = 1e308;
    param MY_MIN_REAL = -2e308;
    // Calculates the eigenvalues from cg_alphas and cg_betas
    proc eigenvalue_driver_initialise(ref chunk_var : [?chunk_domain] chunks.Chunk, ref setting_var : settings.setting, in num_cg_iters: int){
        //chunks per rank for loop
        var diag : [0..<num_cg_iters] real;
        var offdiag : [0..<num_cg_iters] real;

         // Prepare matrix
         for ii in 0..< num_cg_iters do {
            diag[ii] = 1.0 / chunk_var[0].cg_alphas[ii]; // using chunk var array as a single entry array for now

            if ii > 0 then 
                 diag[ii] += chunk_var[0].cg_betas[ii-1] / chunk_var[0].cg_alphas[ii-1];
            if(ii < num_cg_iters-1) then
                offdiag[ii+1] = sqrt(chunk_var[0].cg_betas[ii]) / chunk_var[0].cg_alphas[ii];
         }

        // Calculate the eigenvalues (ignore eigenvectors)
        tqli(diag, offdiag, num_cg_iters);

        chunk_var[0].eigmin = MY_MAX_REAL;  // some large number
        chunk_var[0].eigmax = MY_MIN_REAL; // some large negative number

        // Get minimum and maximum eigenvalues
        for ii in 0..<num_cg_iters do {
            chunk_var[0].eigmin = min(chunk_var[0].eigmin, diag[ii]);
            chunk_var[0].eigmax = max(chunk_var[0].eigmax, diag[ii]);
        }

        // TODO implement die line
        // if(chunks[cc].eigmin < 0.0 || chunks[cc].eigmax < 0.0)
        // {
        // die(__LINE__, __FILE__, "Calculated negative eigenvalues.\n");
        // }

        chunk_var[0].eigmin *= 0.95;
        chunk_var[0].eigmax *= 1.05;

        // print_and_log(settings, 
        // "Min. eigenvalue: \t%.12e\nMax. eigenvalue: \t%.12e\n", 
        // chunks[cc].eigmin, chunks[cc].eigmax);

    
  }

    proc tqli (ref d: [?d_domain], ref e: [?e_domain], inout n: int){

        var m,l,iteration,i : int;
        var s,r,p,g,f,dd,c,b : real;

        for ii in 0..<n-1 do e[ii] = e[ii+1];

        e[n-1]=0.0;

        for l in 0..<n do {
            iteration=0;
            do {
                
                for m in l..<n-1 do{ 
                    dd=abs(d[m])+abs(d[m+1]);
                    if (abs(e[m])+dd == dd) then break;
                }

                if m == l then break;

                
                // if (iter++ == 30){
                //     die(__LINE__, __FILE__,
                //         "Too many iterations in TQLI routine\n");
                // }

                g=(d[l+1]-d[l])/(2.0*e[l]);
                r=sqrt((g*g)+1.0);
                g=d[m]-d[l]+e[l]/(g+sign(r,g));
                s=1.0;
                c=1.0;
                p=0.0;

                for ii in l..#m-1 do{
                    f=s*e[ii];
                    b=c*e[ii];
                    r=sqrt(f*f+g*g);
                    e[ii+1]=r;
                    if(r == 0.0){
                        d[i+1]-=p;
                        e[m]=0.0;
                        continue;
                    }
                    s=f/r;
                    c=g/r;
                    g=d[ii+1]-p;
                    r=(d[ii]-g)*s+2.0*c*b;
                    p=s*r;
                    d[ii+1]=g+p;
                    g=c*r-b;
                }

                d[l]=d[l]-p;
                e[l]=g;
                e[m]=0.0;

            } while (m != l);
        }
    }
    
}