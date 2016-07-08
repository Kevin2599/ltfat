#include "ltfat.h"
#include "ltfat/types.h"
#include "ltfat/macros.h"

struct LTFAT_NAME(iwfac_plan)
{
    ltfatInt b;
    ltfatInt c;
    ltfatInt p;
    ltfatInt q;
    ltfatInt d;
    ltfatInt a;
    ltfatInt M;
    ltfatInt L;
    LTFAT_REAL scaling;
    LTFAT_REAL* sbuf;
    LTFAT_FFTW(plan) p_before;
};

LTFAT_EXTERN int
LTFAT_NAME(iwfac)(const LTFAT_COMPLEX* gf, const ltfatInt L, const ltfatInt R,
                  const ltfatInt a, const ltfatInt M, LTFAT_TYPE* g)
{
    LTFAT_NAME(iwfac_plan)* p = NULL;

    int status = LTFATERR_SUCCESS;

    CHECKSTATUS(
        LTFAT_NAME(iwfac_init)( L, a, M, FFTW_MEASURE, &p),
        "Init failed");


    CHECKSTATUS(
        LTFAT_NAME(iwfac_execute)(p, gf, R, g),
        "Execute failed");

error:
    if (p) LTFAT_NAME(iwfac_done)(&p);
    return status;
}

LTFAT_EXTERN int
LTFAT_NAME(iwfac_init)(const ltfatInt L, const ltfatInt a, const ltfatInt M,
                       unsigned flags, LTFAT_NAME(iwfac_plan)** pout)
{
    LTFAT_NAME(iwfac_plan)* plan = NULL;

    int status = LTFATERR_SUCCESS;
    CHECKNULL(pout);
    CHECK(LTFATERR_NOTPOSARG, a > 0, "a (passed %d) must be positive.", a);
    CHECK(LTFATERR_NOTPOSARG, M > 0, "M (passed %d) must be positive.", M);

    ltfatInt minL = ltfat_lcm(a, M);
    CHECK(LTFATERR_BADARG,
          L > 0 && !(L % minL),
          "L (passed %d) must be positive and divisible by lcm(a,M)=%d.",
          L, minL);

    CHECKMEM(plan = ltfat_calloc(1, sizeof * plan));

    plan->b = L / M;
    ltfatInt h_a, h_m;
    plan->c = ltfat_gcd(a, M, &h_a, &h_m);
    plan->p = a / plan->c;
    plan->q = M / plan->c;
    plan->d = plan->b / plan->p;
    plan->a = a; plan->M = M; plan->L = L;
    plan->scaling = 1.0 / sqrt((double)M) / plan->d;

    CHECKMEM(plan->sbuf = ltfat_malloc(2 * plan->d * sizeof * plan->sbuf));

    /* Create plan. In-place. */
    plan->p_before = LTFAT_FFTW(plan_dft_1d)(plan->d,
                     (LTFAT_COMPLEX*)plan->sbuf, (LTFAT_COMPLEX*)plan->sbuf,
                     FFTW_BACKWARD, flags);

    CHECKINIT(plan->p_before, "FFTW plan creation failed.");

    *pout = plan;
    return status;
error:
    if (plan)
    {
        if (plan->p_before) LTFAT_FFTW(destroy_plan)(plan->p_before);
        ltfat_free(plan->sbuf);
        ltfat_free(plan);
    }
    *pout = NULL;
    return status;
}

LTFAT_EXTERN int
LTFAT_NAME(iwfac_execute)(LTFAT_NAME(iwfac_plan)* plan, const LTFAT_COMPLEX* gf,
                          const ltfatInt R, LTFAT_TYPE* g)
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(plan); CHECKNULL(g); CHECKNULL(gf);
    CHECK(LTFATERR_NOTPOSARG, R > 0, "R (passed %d) must be positive.", R);

    const ltfatInt c = plan->c;
    const ltfatInt p = plan->p;
    const ltfatInt q = plan->q;
    const ltfatInt d = plan->d;
    const ltfatInt M = plan->M;
    const ltfatInt a = plan->a;
    const ltfatInt L = plan->L;

    LTFAT_REAL scaling = plan->scaling;
    LTFAT_REAL* sbuf = plan->sbuf;
    LTFAT_FFTW(plan) p_before = plan->p_before;
    ltfatInt rem, negrem;

    const ltfatInt ld3 = c * p * q * R;
    LTFAT_REAL* gfp = (LTFAT_REAL*)gf;

    for (ltfatInt r = 0; r < c; r++)
    {
        for (ltfatInt w = 0; w < R; w++)
        {
            for (ltfatInt l = 0; l < q; l++)
            {
                for (ltfatInt k = 0; k < p; k++)
                {
                    negrem = positiverem(k * M - l * a, L);
                    for (ltfatInt s = 0; s < 2 * d; s += 2)
                    {
                        sbuf[s]   = gfp[s * ld3] * scaling;
                        sbuf[s + 1] = gfp[s * ld3 + 1] * scaling;
                    }

                    LTFAT_FFTW(execute)(p_before);

                    for (ltfatInt s = 0; s < d; s++)
                    {
                        rem = (negrem + s * p * M) % L;
#ifdef LTFAT_COMPLEXTYPE
                        LTFAT_REAL* gTmp = (LTFAT_REAL*) & (g[r + rem + L * w]);
                        gTmp[0] = sbuf[2 * s];
                        gTmp[1] = sbuf[2 * s + 1];
#else
                        g[r + rem + L * w] = sbuf[2 * s];
#endif
                    }
                    gfp += 2;
                }
            }
        }
    }

error:
    return status;
}

LTFAT_EXTERN int
LTFAT_NAME(iwfac_done)(LTFAT_NAME(iwfac_plan)** pout)
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(pout);
    CHECKNULL(*pout);

    LTFAT_FFTW(destroy_plan)((*pout)->p_before);
    ltfat_free((*pout)->sbuf);
    ltfat_free(*pout);
    *pout = NULL;
error:
    return status;
}




