#!/usr/bin/env python3
"""Generate a simple logo for the Sike app"""

try:
    from PIL import Image, ImageDraw, ImageFont
    import sys
    
    # Create a 512x512 image with gradient background
    size = 512
    img = Image.new('RGB', (size, size))
    draw = ImageDraw.Draw(img)
    
    # Create gradient background (light blue to pink to purple)
    for y in range(size):
        for x in range(size):
            # Calculate position (0.0 to 1.0)
            progress = (x + y) / (size * 2)
            
            # Interpolate between light blue, pink, and purple
            if progress < 0.5:
                # Light blue to pink
                t = progress * 2
                r = int(135 + (233 - 135) * t)
                g = int(206 + (30 - 206) * t)
                b = int(235 + (99 - 235) * t)
            else:
                # Pink to purple
                t = (progress - 0.5) * 2
                r = int(233 + (156 - 233) * t)
                g = int(30 + (39 - 30) * t)
                b = int(99 + (176 - 99) * t)
            
            img.putpixel((x, y), (r, g, b))
    
    # Draw a white checkmark
    draw.line([(170, 256), (220, 306)], fill='white', width=40)
    draw.line([(220, 306), (342, 184)], fill='white', width=40)
    
    # Try to draw "S" text (may fail without font, so we'll skip if needed)
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 120)
        draw.text((256, 340), "S", fill='white', font=font, anchor="mm")
    except:
        # Fallback: draw a simple circle outline as placeholder
        draw.ellipse([156, 340, 356, 440], outline='white', width=8)
    
    # Save the image
    img.save('assets/images/logo.png', 'PNG')
    print("Logo created successfully at assets/images/logo.png")
    
except ImportError:
    print("PIL/Pillow not installed. Please install it with: pip3 install pillow")
    sys.exit(1)
except Exception as e:
    print(f"Error creating logo: {e}")
    sys.exit(1)