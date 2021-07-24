#include <fstream>
#include <iostream>
#include <cstdlib>
#include "obj_dir/Vjt7759.h"
#include "verilated_vcd_c.h"


using DUT=Vjt7759;

vluint64_t simtime=0;
bool trace = true;
const vluint64_t HPERIOD=195;
DUT dut;
VerilatedVcdC* tfp;

void clock( int times ) {
    static int cnt=0;
    times = times << 1;
    while( times-- ) {
        dut.cen = (cnt&7)==0;
        dut.clk = 1-dut.clk;
        simtime += HPERIOD;
        dut.eval();
        if( trace ) tfp->dump(simtime);
        if( dut.clk ) {
            cnt++;
        }
    }
}

void reset() {
    dut.rst = 1;
    dut.mdn = 1;
    dut.wrn = 1;
    clock( 10 );
    dut.rst = 0;
    clock( 10 );
}

void write( char b ) {
    dut.din = b;
    dut.cs  = 1;
    dut.wrn = 0;
    clock(4);
    dut.cs  = 0;
    dut.wrn = 1;
}

void fill( char *buf, char *enc, int len ) {
    int k=0, aux;
    int e=0;
    buf[k++]=0;
    while( k<len ) {
        if(k==len-1) {
            buf[k++] = 0;
            break;
        }
        int cmd = rand();
        switch( (cmd&0xc0)>>6 ) {
            case 0:
                buf[k++] = cmd;
                continue;
            case 1:
                if( len-k>=258 ) {
                    buf[k++] = cmd;
                    for(int j=0; j<128; j++ ) {
                        enc[e++] = buf[k++] = rand();
                    }
                }
                continue;
            case 2:
                aux = rand()&0xff;
                if( len-k > aux+2) {
                    buf[k++] = cmd;
                    buf[k++] = aux;
                    aux>>=1;
                    while( aux-- ) {
                        enc[e++] = buf[k++] = rand();
                    }
                }
                continue;
            default:
                continue;
        }
    }
    while( e < len ) enc[e++]=0;
}

int main() {
    VerilatedVcdC tf;
    tfp = &tf;

    if( trace ) {
        Verilated::traceEverOn(true);
        dut.trace(tfp,99);
        //tf.open("/dev/stdout");
        tfp->open("test.vcd");
    }

    reset();

    const int LEN=2*1024;
    char buffer[LEN], enc[LEN];
    for( int loops=0; loops < 10; loops ++ ) {
        dut.mdn = 0;
        clock( 4 );
        write( 0xff );
        clock( 4 );

        fill( buffer, enc, sizeof(buffer) );
        // feed and compare
        const int TIMEOUT=20'000;
        int k=0, timeout=TIMEOUT;
        int drqn_l=1, cen_dec_l=0;
        int check=0;
        while( k<sizeof(buffer) && --timeout ) {
            clock(1);
            if( !dut.drqn && drqn_l ) {
                write( buffer[k++] );
                //printf("%d\n",k);
                timeout = TIMEOUT;
            }
            drqn_l = dut.drqn;
            if( dut.debug_cen_dec && !cen_dec_l && dut.debug_dec_rst==0 ) {
                char good = enc[check>>1];
                if( (check&1) == 0 ) {
                    good >>= 4;
                }
                check++;
                good &= 0xf;
                printf("%X - %X\n", good, dut.debug_nibble );
                if( good != dut.debug_nibble ) {
                    printf("ERROR: unexpected encoded value\n");
                    //for( int l=(check>>1)-2; l<(check>>1)+4 && l<LEN ; l++ ) {
                    //    printf("%02X ", enc[l]&0xff);
                    //}
                    for( int l=0; l<(check>>1)+4; l++ ) {
                        printf("%02X ", enc[l]&0xff);
                        if( (l&0xf) == 0xf ) printf("\n");
                    }
                    printf("\nBuffer ---- \n");
                    for( int l=0; l<k+4 && l<LEN; l++ ) {
                        printf("%02X ", buffer[l]&0xff);
                        if( (l&0xf) == 0xf ) printf("\n");
                    }
                    printf("\n\n");
                    goto done;
                }
                if( check>=LEN ) {
                    break;
                }
            }
        }
        dut.mdn = 1;
        clock(4);
    }
done:
    return 0;
}