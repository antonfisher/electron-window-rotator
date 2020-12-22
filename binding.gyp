{
    "targets": [
        {
            "target_name": "NativeExtension",
            "sources": ["NativeExtension.cc"],
            "link_settings": {
                "conditions": [
                    [
                        'OS=="mac"', {
                            "sources": [
                                "rotator.mm"
                            ],
                        }
                    ]
                ]
            }
        }
    ],
}
