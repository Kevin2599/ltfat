#include "ltfat.h"
#include "ltfat/types.h"
#include "ltfat/macros.h"

LTFAT_EXTERN int
LTFAT_NAME(gabdual_long)(const LTFAT_TYPE* g,
                         const ltfatInt L, const ltfatInt R, const ltfatInt a,
                         const ltfatInt M, LTFAT_TYPE* gd)
{
    LTFAT_COMPLEX* gf = NULL;
    LTFAT_COMPLEX* gdf = NULL;

    int status = LTFATERR_SUCCESS;
    CHECK(LTFATERR_NOTPOSARG, R > 0, "R (passed %d) must be positive.", R);
    CHECK(LTFATERR_NOTAFRAME, M >= a, "Not a frame. Check if M>=a.");
    ltfatInt minL = ltfat_lcm(a, M);
    CHECK(LTFATERR_BADARG, L > 0 && !(L % minL),
          "L (passed %d) must be positive and divisible by lcm(a,M)=%d.", L, minL);
    // a,M, g and gd are checked further

    CHECKMEM( gf = ltfat_malloc(L * R * sizeof * gf));
    CHECKMEM( gdf = ltfat_malloc(L * R * sizeof * gdf));

#ifdef LTFAT_COMPLEXTYPE

    CHECKSTATUS( LTFAT_NAME(wfac)(g, L, R, a, M, gf), "wfac failed");
    LTFAT_NAME_REAL(gabdual_fac)(gf, L, R, a, M, gdf);
    CHECKSTATUS( LTFAT_NAME(iwfac)(gdf, L, R, a, M, gd), "iwfac failed");

#else

    LTFAT_NAME_REAL(wfacreal)(g, L, R, a, M, gf);
    LTFAT_NAME_REAL(gabdualreal_fac)(gf, L, R, a, M, gdf);
    LTFAT_NAME_REAL(iwfacreal)(gdf, L, R, a, M, gd);

#endif

error:
    LTFAT_SAFEFREEALL(gdf, gf);
    return status;
}


LTFAT_EXTERN int
LTFAT_NAME(gabdual_fir)(const LTFAT_TYPE* g, const ltfatInt gl,
                        const ltfatInt L, const ltfatInt a,
                        const ltfatInt M, const ltfatInt gdl, LTFAT_TYPE* gd)
{
    LTFAT_TYPE* tmpLong = NULL;

    int status = LTFATERR_SUCCESS;
    CHECKNULL(g); CHECKNULL(gd);
    CHECK(LTFATERR_NOTPOSARG, gl > 0, "gl must be positive");
    CHECK(LTFATERR_NOTPOSARG, L > 0, "L must be positive");
    CHECK(LTFATERR_NOTPOSARG, gdl > 0, "gdl must be positive");
    CHECK(LTFATERR_BADARG, L >= gl && L >= gdl,
          "L>=gl && L>= gdl must hold. Passed L=%d, gl=%d, gdl=%d", L, gl, gdl);

    CHECKMEM( tmpLong = ltfat_malloc(L * sizeof * tmpLong));

    CHECKSTATUS( LTFAT_NAME(fir2long)(g, gl, L, tmpLong), "fir2long failed");
    CHECKSTATUS( LTFAT_NAME(gabdual_long)(tmpLong, L, 1, a, M, tmpLong),
                 "gabdual_long failed");
    CHECKSTATUS( LTFAT_NAME(long2fir)(tmpLong, L, gdl, gd), "long2fir failed");

error:
    if (tmpLong) ltfat_free(tmpLong);
    return status;
}
