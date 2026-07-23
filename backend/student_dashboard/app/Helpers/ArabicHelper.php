<?php

namespace App\Helpers;

class ArabicHelper
{
    /**
     * Shape Arabic text for PDF engines that do not perform Arabic shaping.
     */
    public static function fixArabic($text, bool $reverse = true)
    {
        if ($text === null || $text === '') {
            return $text;
        }

        $text = str_replace(["\xc2\xa0", '&nbsp;'], ' ', (string) $text);
        $shaped = self::reshape($text);

        return $reverse ? self::reverseRtl($shaped) : $shaped;
    }

    private static function reshape(string $text): string
    {
        $map = self::formsMap();
        $noLeftConnect = array_flip(['ا', 'أ', 'إ', 'آ', 'د', 'ذ', 'ر', 'ز', 'و', 'ؤ', 'ة', 'ى']);
        $chars = self::splitUtf8($text);
        $result = [];
        $count = count($chars);

        for ($i = 0; $i < $count; $i++) {
            $current = $chars[$i];

            if ($current === 'ل' && $i < $count - 1) {
                $next = $chars[$i + 1];
                $lamAlef = match ($next) {
                    'ا' => ["\u{FEFB}", "\u{FEFC}"],
                    'أ' => ["\u{FEF7}", "\u{FEF8}"],
                    'إ' => ["\u{FEF9}", "\u{FEFA}"],
                    'آ' => ["\u{FEF5}", "\u{FEF6}"],
                    default => null,
                };

                if ($lamAlef !== null) {
                    $prev = self::previousArabicChar($chars, $i, $map);
                    $connectPrev = $prev !== null && !isset($noLeftConnect[$prev]);
                    $result[] = $connectPrev ? $lamAlef[1] : $lamAlef[0];
                    $i++;
                    continue;
                }
            }

            if (!isset($map[$current])) {
                $result[] = $current;
                continue;
            }

            $prev = self::previousArabicChar($chars, $i, $map);
            $next = self::nextArabicChar($chars, $i, $map);
            $connectPrev = $prev !== null && !isset($noLeftConnect[$prev]);
            $connectNext = $next !== null;

            if ($connectPrev && $connectNext) {
                $result[] = $map[$current][2];
            } elseif ($connectPrev) {
                $result[] = $map[$current][3];
            } elseif ($connectNext) {
                $result[] = $map[$current][1];
            } else {
                $result[] = $map[$current][0];
            }
        }

        return implode('', $result);
    }

    private static function previousArabicChar(array $chars, int $index, array $map): ?string
    {
        for ($i = $index - 1; $i >= 0; $i--) {
            if (isset($map[$chars[$i]])) {
                return $chars[$i];
            }

            if (!self::isArabicMark($chars[$i])) {
                return null;
            }
        }

        return null;
    }

    private static function nextArabicChar(array $chars, int $index, array $map): ?string
    {
        $count = count($chars);
        for ($i = $index + 1; $i < $count; $i++) {
            if (isset($map[$chars[$i]])) {
                return $chars[$i];
            }

            if (!self::isArabicMark($chars[$i])) {
                return null;
            }
        }

        return null;
    }

    private static function isArabicMark(string $char): bool
    {
        return preg_match('/^[\x{064B}-\x{065F}\x{0670}]$/u', $char) === 1;
    }

    private static function reverseRtl(string $text): string
    {
        preg_match_all('/([A-Za-z0-9#\/:._-]+|[\s]+|.)/u', $text, $matches);

        return implode('', array_reverse($matches[0]));
    }

    private static function splitUtf8(string $text): array
    {
        return preg_split('//u', $text, -1, PREG_SPLIT_NO_EMPTY) ?: [];
    }

    private static function formsMap(): array
    {
        return [
            'ء' => ["\u{FE80}", "\u{FE80}", "\u{FE80}", "\u{FE80}"],
            'آ' => ["\u{FE81}", "\u{FE81}", "\u{FE82}", "\u{FE82}"],
            'أ' => ["\u{FE83}", "\u{FE83}", "\u{FE84}", "\u{FE84}"],
            'ؤ' => ["\u{FE85}", "\u{FE85}", "\u{FE86}", "\u{FE86}"],
            'إ' => ["\u{FE87}", "\u{FE87}", "\u{FE88}", "\u{FE88}"],
            'ئ' => ["\u{FE89}", "\u{FE8B}", "\u{FE8C}", "\u{FE8A}"],
            'ا' => ["\u{FE8D}", "\u{FE8D}", "\u{FE8E}", "\u{FE8E}"],
            'ب' => ["\u{FE8F}", "\u{FE91}", "\u{FE92}", "\u{FE90}"],
            'ة' => ["\u{FE93}", "\u{FE93}", "\u{FE94}", "\u{FE94}"],
            'ت' => ["\u{FE95}", "\u{FE97}", "\u{FE98}", "\u{FE96}"],
            'ث' => ["\u{FE99}", "\u{FE9B}", "\u{FE9C}", "\u{FE9A}"],
            'ج' => ["\u{FE9D}", "\u{FE9F}", "\u{FEA0}", "\u{FE9E}"],
            'ح' => ["\u{FEA1}", "\u{FEA3}", "\u{FEA4}", "\u{FEA2}"],
            'خ' => ["\u{FEA5}", "\u{FEA7}", "\u{FEA8}", "\u{FEA6}"],
            'د' => ["\u{FEA9}", "\u{FEA9}", "\u{FEAA}", "\u{FEAA}"],
            'ذ' => ["\u{FEAB}", "\u{FEAB}", "\u{FEAC}", "\u{FEAC}"],
            'ر' => ["\u{FEAD}", "\u{FEAD}", "\u{FEAE}", "\u{FEAE}"],
            'ز' => ["\u{FEAF}", "\u{FEAF}", "\u{FEB0}", "\u{FEB0}"],
            'س' => ["\u{FEB1}", "\u{FEB3}", "\u{FEB4}", "\u{FEB2}"],
            'ش' => ["\u{FEB5}", "\u{FEB7}", "\u{FEB8}", "\u{FEB6}"],
            'ص' => ["\u{FEB9}", "\u{FEBB}", "\u{FEBC}", "\u{FEBA}"],
            'ض' => ["\u{FEBD}", "\u{FEBF}", "\u{FEC0}", "\u{FEBE}"],
            'ط' => ["\u{FEC1}", "\u{FEC3}", "\u{FEC4}", "\u{FEC2}"],
            'ظ' => ["\u{FEC5}", "\u{FEC7}", "\u{FEC8}", "\u{FEC6}"],
            'ع' => ["\u{FEC9}", "\u{FECB}", "\u{FECC}", "\u{FECA}"],
            'غ' => ["\u{FECD}", "\u{FECF}", "\u{FED0}", "\u{FECE}"],
            'ف' => ["\u{FED1}", "\u{FED3}", "\u{FED4}", "\u{FED2}"],
            'ق' => ["\u{FED5}", "\u{FED7}", "\u{FED8}", "\u{FED6}"],
            'ك' => ["\u{FED9}", "\u{FEDB}", "\u{FEDC}", "\u{FEDA}"],
            'ل' => ["\u{FEDD}", "\u{FEDF}", "\u{FEE0}", "\u{FEDE}"],
            'م' => ["\u{FEE1}", "\u{FEE3}", "\u{FEE4}", "\u{FEE2}"],
            'ن' => ["\u{FEE5}", "\u{FEE7}", "\u{FEE8}", "\u{FEE6}"],
            'ه' => ["\u{FEE9}", "\u{FEEB}", "\u{FEEC}", "\u{FEEA}"],
            'و' => ["\u{FEED}", "\u{FEED}", "\u{FEEE}", "\u{FEEE}"],
            'ى' => ["\u{FEEF}", "\u{FEEF}", "\u{FEF0}", "\u{FEF0}"],
            'ي' => ["\u{FEF1}", "\u{FEF3}", "\u{FEF4}", "\u{FEF2}"],
        ];
    }
}
