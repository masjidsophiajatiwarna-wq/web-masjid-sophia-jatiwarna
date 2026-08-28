import { test, describe } from 'node:test';
import assert from 'node:assert/strict';

// Logika Hisab Astronomis Waktu Shalat Presisi Jatiwarna (-6.310391, 106.921264, WIB UTC+7)
function calculatePrayerTimes(dateStr, ikhtiyatMin = 2) {
    const d = dateStr ? new Date(dateStr + 'T00:00:00') : new Date();
    const dayOfYear = Math.floor((d - new Date(d.getFullYear(), 0, 0)) / 1000 / 60 / 60 / 24);
    const rad = Math.PI / 180;
    const declination = 23.45 * Math.sin(rad * (360 / 365) * (dayOfYear - 81));
    const eqTime = 9.87 * Math.sin(rad * 2 * (360 / 365) * (dayOfYear - 81)) - 7.53 * Math.cos(rad * (360 / 365) * (dayOfYear - 81)) - 1.5 * Math.sin(rad * (360 / 365) * (dayOfYear - 81));
    
    const transit = 12 + (105 - 106.921264) / 15 - (eqTime / 60);
    const lat = -6.310391 * rad;
    const dec = declination * rad;
    
    function hourAngle(alt) {
        const cosHA = (Math.sin(alt * rad) - Math.sin(lat) * Math.sin(dec)) / (Math.cos(lat) * Math.cos(dec));
        if (cosHA > 1) return 0;
        if (cosHA < -1) return 180;
        return Math.acos(cosHA) / rad;
    }

    const haSubuh = hourAngle(-20);
    const haTerbit = hourAngle(-0.833);
    const haIsya = hourAngle(-18);
    
    const asharAlt = Math.atan(1 / (1 + Math.tan(Math.abs(lat - dec)))) / rad;
    const haAshar = hourAngle(asharAlt);

    function toTimeString(hoursDec, offsetMinutes = 0) {
        const totalMinutes = Math.round((hoursDec * 60) + offsetMinutes);
        const hh = Math.floor(totalMinutes / 60) % 24;
        const mm = totalMinutes % 60;
        return `${String(hh).padStart(2, '0')}:${String(mm).padStart(2, '0')}`;
    }

    const dzuhurHour = transit;
    const subuhHour = transit - (haSubuh / 15);
    const terbitHour = transit - (haTerbit / 15);
    const asharHour = transit + (haAshar / 15);
    const maghribHour = transit + (haTerbit / 15);
    const isyaHour = transit + (haIsya / 15);
    const imsakHour = subuhHour - (10 / 60);
    const dhuhaHour = terbitHour + (25 / 60);

    const ikh = (ikhtiyatMin !== undefined && !isNaN(parseInt(ikhtiyatMin, 10))) ? parseInt(ikhtiyatMin, 10) : 2;

    return {
        imsak: toTimeString(imsakHour, ikh),
        subuh: toTimeString(subuhHour, ikh),
        terbit: toTimeString(terbitHour, 0),
        dhuha: toTimeString(dhuhaHour, ikh),
        dzuhur: toTimeString(dzuhurHour, ikh),
        ashar: toTimeString(asharHour, ikh),
        maghrib: toTimeString(maghribHour, ikh),
        isya: toTimeString(isyaHour, ikh)
    };
}

describe('Hisab Waktu Shalat & Ikhtiyat Kemenag Jatiwarna', () => {

    test('1. Menghasilkan jadwal 8 parameter waktu shalat lengkap format HH:MM', () => {
        const times = calculatePrayerTimes('2026-08-29', 2);
        
        const requiredKeys = ['imsak', 'subuh', 'terbit', 'dhuha', 'dzuhur', 'ashar', 'maghrib', 'isya'];
        requiredKeys.forEach(key => {
            assert.ok(times[key], `Jadwal ${key} harus terdefinisi`);
            assert.match(times[key], /^\d{2}:\d{2}$/, `Format waktu ${key} harus HH:MM`);
        });
    });

    test('2. Urutan kronologis waktu shalat harian valid (Imsak < Subuh < Terbit < Dhuha < Dzuhur < Ashar < Maghrib < Isya)', () => {
        const times = calculatePrayerTimes('2026-08-29', 2);

        const toMinutes = (timeStr) => {
            const [h, m] = timeStr.split(':').map(Number);
            return h * 60 + m;
        };

        assert.ok(toMinutes(times.imsak) < toMinutes(times.subuh), 'Imsak harus mendahului Subuh');
        assert.ok(toMinutes(times.subuh) < toMinutes(times.terbit), 'Subuh harus mendahului Terbit');
        assert.ok(toMinutes(times.terbit) < toMinutes(times.dhuha), 'Terbit harus mendahului Dhuha');
        assert.ok(toMinutes(times.dhuha) < toMinutes(times.dzuhur), 'Dhuha harus mendahului Dzuhur');
        assert.ok(toMinutes(times.dzuhur) < toMinutes(times.ashar), 'Dzuhur harus mendahului Ashar');
        assert.ok(toMinutes(times.ashar) < toMinutes(times.maghrib), 'Ashar harus mendahului Maghrib');
        assert.ok(toMinutes(times.maghrib) < toMinutes(times.isya), 'Maghrib harus mendahului Isya');
    });

    test('3. Menit ikhtiyat (+2 menit) menambah waktu shalat secara presisi', () => {
        const timesDefault = calculatePrayerTimes('2026-08-29', 0); // Tanpa ikhtiyat
        const timesWithIkhtiyat = calculatePrayerTimes('2026-08-29', 2); // Ikhtiyat +2

        const toMinutes = (timeStr) => {
            const [h, m] = timeStr.split(':').map(Number);
            return h * 60 + m;
        };

        // Dzuhur dengan ikhtiyat harus 2 menit lebih lambat
        const diffDzuhur = toMinutes(timesWithIkhtiyat.dzuhur) - toMinutes(timesDefault.dzuhur);
        assert.equal(diffDzuhur, 2, 'Ikhtiyat 2 menit harus menambahkan 2 menit pada jadwal dzuhur');
    });

});
