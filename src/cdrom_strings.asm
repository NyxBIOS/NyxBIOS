; Additional cdrom log strings

str_log_pvd_read    db 'CDROM: reading PVD LBA=10h',13,10,0
str_err_pvd_sig     db 'CDROM: PVD invalid sig',13,10,0
str_log_br_ok       db 'CDROM: BR sig OK',13,10,0
str_log_cat_lba     db 'CDROM: CAT LBA=',0
str_log_cat_read    db 'CDROM: reading CAT',13,10,0
str_err_cat_sig     db 'CDROM: CAT invalid ID',13,10,0
str_log_img_parse   db 'CDROM: parsing img entry',13,10,0
str_log_img_bootable db 'CDROM: entry bootable',13,10,0
str_log_img_seg     db 'CDROM: load SEG=',0
str_log_img_cnt     db 'CDROM: sector CNT=',0
str_log_img_lba     db 'CDROM: img LBA=',0
str_log_img_load    db 'CDROM: loading img to SEG:7C00',13,10,0
str_log_handoff     db 'CDROM: handoff to bootloader',13,10,0
str_cdrom_fail_stage db 'CDROM: failed at LOAD',13,10,0
str_log_nl          db 13,10,0

