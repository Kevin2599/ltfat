/** \defgroup windows Gabor Windows 
 * \addtogroup windows
 * @{
 */

#ifndef _CI_WINDOWS_H
#define _CI_WINDOWS_H

typedef enum
{
    LTFAT_HANN, LTFAT_HANNING, LTFAT_NUTTALL10,
    LTFAT_SQRTHANN, LTFAT_COSINE, LTFAT_SINE,
    LTFAT_HAMMING,
    LTFAT_NUTTALL01,
    LTFAT_SQUARE, LTFAT_RECT,
    LTFAT_TRIA, LTFAT_TRIANGULAR, LTFAT_BARTLETT,
    LTFAT_SQRTTRIA,
    LTFAT_BLACKMAN,
    LTFAT_BLACKMAN2,
    LTFAT_NUTTALL, LTFAT_NUTTALL12,
    LTFAT_OGG, LTFAT_ITERSINE,
    LTFAT_NUTTALL20,
    LTFAT_NUTTALL11,
    LTFAT_NUTTALL02,
    LTFAT_NUTTALL30,
    LTFAT_NUTTALL21,
    LTFAT_NUTTALL03,
}
LTFAT_FIRWIN;

#endif /* _CI_WINDOWS_H */

LTFAT_EXTERN int
LTFAT_NAME(firwin)(LTFAT_FIRWIN win, int gl, LTFAT_TYPE* g);


/** @} */
