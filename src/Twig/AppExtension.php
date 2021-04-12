<?php

namespace App\Twig;

use Twig\Extension\AbstractExtension;
use Twig\TwigFilter;

class AppExtension extends AbstractExtension
{
    public function getFilters()
    {
        return [
            new TwigFilter('pack', [$this, 'packBinary']),
            new TwigFilter('unpack', [$this, 'unpackBinary']),
        ];
    }

    public function packBinary($uuid)
    {
        return pack("H*", str_replace('-', '', $uuid));
    }

    public function unpackBinary($binary)
    {
        $string = unpack("H*", $binary);
        return preg_replace("/([0-9a-f]{8})([0-9a-f]{4})([0-9a-f]{4})([0-9a-f]{4})([0-9a-f]{12})/", "$1-$2-$3-$4-$5", $string['1']);
    }
}