param(
    [switch] $IdleOnly,
    [switch] $CleanedOnly,
    [switch] $KeyOnly
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

Add-Type -ReferencedAssemblies 'System.Drawing.dll' -TypeDefinition @"
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class PlayerFrameCleaner {
    private static bool IsMagenta(byte r, byte g, byte b, byte a) {
        int peak = Math.Max(r, b);
        return a > 0 && peak >= 72 && g <= 225 && r - g >= 24 && b - g >= 24;
    }

    private static bool IsBackground(byte r, byte g, byte b, byte a) {
        bool nearWhite = r > 235 && g > 235 && b > 235;
        bool nearBlack = r < 28 && g < 28 && b < 28;
        return a == 0 || nearWhite || nearBlack || IsMagenta(r, g, b, a);
    }

    public static void Clean(string sourcePath, string outputPath) {
        using (var source = new Bitmap(sourcePath))
        using (var image = new Bitmap(source.Width, source.Height, PixelFormat.Format32bppArgb)) {
            using (var graphics = Graphics.FromImage(image)) {
                graphics.DrawImageUnscaled(source, 0, 0);
            }

            var rectangle = new Rectangle(0, 0, image.Width, image.Height);
            var data = image.LockBits(rectangle, ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
            int stride = Math.Abs(data.Stride);
            var bytes = new byte[stride * image.Height];
            Marshal.Copy(data.Scan0, bytes, 0, bytes.Length);
            var visited = new bool[image.Width * image.Height];
            var queue = new Queue<int>();

            for (int x = 0; x < image.Width; x++) {
                queue.Enqueue(x);
                queue.Enqueue(x + (image.Height - 1) * image.Width);
            }
            for (int y = 0; y < image.Height; y++) {
                queue.Enqueue(y * image.Width);
                queue.Enqueue((image.Width - 1) + y * image.Width);
            }

            while (queue.Count > 0) {
                int index = queue.Dequeue();
                if (index < 0 || index >= visited.Length || visited[index]) continue;
                visited[index] = true;
                int x = index % image.Width;
                int y = index / image.Width;
                int offset = y * stride + x * 4;
                byte b = bytes[offset];
                byte g = bytes[offset + 1];
                byte r = bytes[offset + 2];
                byte a = bytes[offset + 3];
                if (!IsBackground(r, g, b, a)) continue;
                bytes[offset] = 0;
                bytes[offset + 1] = 0;
                bytes[offset + 2] = 0;
                bytes[offset + 3] = 0;
                if (x > 0) queue.Enqueue(index - 1);
                if (x < image.Width - 1) queue.Enqueue(index + 1);
                if (y > 0) queue.Enqueue(index - image.Width);
                if (y < image.Height - 1) queue.Enqueue(index + image.Width);
            }

            for (int y = 0; y < image.Height; y++) {
                for (int x = 0; x < image.Width; x++) {
                    int offset = y * stride + x * 4;
                    byte b = bytes[offset];
                    byte g = bytes[offset + 1];
                    byte r = bytes[offset + 2];
                    byte a = bytes[offset + 3];
                    if (a == 0 || IsMagenta(r, g, b, a)) {
                        bytes[offset] = 0;
                        bytes[offset + 1] = 0;
                        bytes[offset + 2] = 0;
                        bytes[offset + 3] = 0;
                    }
                }
            }

            Marshal.Copy(bytes, 0, data.Scan0, bytes.Length);
            image.UnlockBits(data);
            image.Save(outputPath, ImageFormat.Png);
        }
    }
}
"@

$sourceDirectory = (Resolve-Path (Join-Path $PSScriptRoot '..\data\player')).Path
if ($CleanedOnly) {
    $sourceDirectory = Join-Path $sourceDirectory 'cleaned'
}
$outputDirectory = if ($CleanedOnly) { $sourceDirectory } else { Join-Path $sourceDirectory 'cleaned' }
New-Item -ItemType Directory -Force $outputDirectory | Out-Null

function Test-Magenta([System.Drawing.Color] $pixel) {
    # The generated key is not a single RGB value. Its antialiased edge can
    # be pink, violet, or red-magenta, while the hero's dark purple hair is
    # intentionally much darker. Keep the key test brightness-aware so those
    # two colors do not get confused.
    $peak = [Math]::Max($pixel.R, $pixel.B)
    return ($pixel.A -gt 0 -and
        $peak -ge 72 -and
        $pixel.G -le 225 -and
        ($pixel.R - $pixel.G) -ge 24 -and
        ($pixel.B - $pixel.G) -ge 24)
}

function Test-Background([System.Drawing.Color] $pixel) {
    $nearWhite = $pixel.R -gt 235 -and $pixel.G -gt 235 -and $pixel.B -gt 235
    $nearBlack = $pixel.R -lt 28 -and $pixel.G -lt 28 -and $pixel.B -lt 28
    return $pixel.A -eq 0 -or $nearWhite -or $nearBlack -or (Test-Magenta $pixel)
}

$sourceFiles = if ($CleanedOnly) {
    Get-ChildItem $sourceDirectory -Filter '*-frame-*.png'
} elseif ($IdleOnly) {
    Get-ChildItem $sourceDirectory -Filter 'frame-*.png'
} else {
    Get-ChildItem $sourceDirectory | Where-Object {
        $_.Name -like '*-frame-*.png' -or $_.Name -like 'frame-*.png'
    }
}

foreach ($sourceFile in $sourceFiles) {
    $temporaryFile = Join-Path $outputDirectory ($sourceFile.BaseName + '.tmp.png')
    $destinationFile = Join-Path $outputDirectory $sourceFile.Name
    [PlayerFrameCleaner]::Clean($sourceFile.FullName, $temporaryFile)
    Move-Item -LiteralPath $temporaryFile -Destination $destinationFile -Force
    Write-Output $(if ($KeyOnly) { "key-cleaned $($sourceFile.Name)" } else { "cleaned $($sourceFile.Name)" })
}
