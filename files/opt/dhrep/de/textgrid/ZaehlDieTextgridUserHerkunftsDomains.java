package de.textgrid;

import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.io.LineNumberReader;
import java.util.HashMap;

/**
 * <p>
 * Diese Klasse braucht keine Dokumentation, weil sie ganz einfach zu verstehen
 * ist...
 * </p>
 * 
 * @author Stefan E. Funk, SUB Göttingen
 * @since 2016-07-14
 * @version 2016-07-14
 */
public class ZaehlDieTextgridUserHerkunftsDomains {

	public static void main(String[] args) throws IOException {

		File dieStatistikDatei = new File(args[0]);
		LineNumberReader derReaderDerDieStatistikDateiLiest = new LineNumberReader(new FileReader(dieStatistikDatei));

		HashMap<String, Integer> dieHashMapDerDomains = new HashMap<String, Integer>();
		while (derReaderDerDieStatistikDateiLiest.ready()) {
			String jeweilsEineEMailAdresse = derReaderDerDieStatistikDateiLiest.readLine();
			if (jeweilsEineEMailAdresse.lastIndexOf(".") != -1) {
				String dieDomainEndungOhneEMailAdresse = jeweilsEineEMailAdresse
						.substring(jeweilsEineEMailAdresse.lastIndexOf(".") + 1);
				if (dieHashMapDerDomains.containsKey(dieDomainEndungOhneEMailAdresse)) {
					dieHashMapDerDomains.put(dieDomainEndungOhneEMailAdresse,
							dieHashMapDerDomains.get(dieDomainEndungOhneEMailAdresse) + 1);
				} else {
					dieHashMapDerDomains.put(dieDomainEndungOhneEMailAdresse, 1);
				}
			}
		}

		int dieAnzahlAllerEMailAdressen = 0;
		for (Integer dieAnzahlJeweilsEinerDomain : dieHashMapDerDomains.values()) {
			dieAnzahlAllerEMailAdressen = dieAnzahlAllerEMailAdressen + dieAnzahlJeweilsEinerDomain;
		}

		derReaderDerDieStatistikDateiLiest.close();

		System.out.println(dieHashMapDerDomains + " = " + dieAnzahlAllerEMailAdressen);
	}

}
