function jd = datenum_to_javatime(d)
cal = java.util.GregorianCalendar;
jd = round((d - datenum('01/01/1970','dd/mm/yyyy')) * 24*60*60*1e3 - cal.get(cal.ZONE_OFFSET)- cal.get(cal.DST_OFFSET));