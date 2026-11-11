
#Region Internal

// Decomposes the magnetic card track data according to templates.   
//
// Parameters:
// TrackData - Array -array of strings. Values obtained from tracks.
// TrackParameters - Array -an array of structures containing device configuration parameters, where:
//  * Use - Boolean - indicates whether the track is being used.
//  * TrackNumber - Number - the sequence number of track 1-3.
//
// Returns:
// Array of Structure:
// *Template - CatalogRef.MagneticStripeCardTemplates - ;
// *TrackData - Structure:
//  	**Field - String
//  	**Simple - Arbitrary - 
//
Function DecryptMagneticCardCode(TrackData, TrackParameters) Export
	
	If CommonCEL.MagneticCardTemplatesAreUsed() Then
		ModuleName = "Catalogs.MagneticStripeCardTemplates";
		ModuleMagneticCardTemplates = CommonCEL.CommonModule(ModuleName);
		Return ModuleMagneticCardTemplates.DecryptMagneticCardCode(TrackData, TrackParameters);
	Else
		 MessageText = NStr("vi = 'Không thể thực hiện lệnh, vì phân hệ ""%Couples1%"" không hợp lệ.';
							|ru = 'Выполнение команды невозможно, поскольку подсистема ""%Couples1%"" недоступна.';
							|en = 'Cannot run the command as the ""%Couples1%"" subsystem is unavailable.'; fa = 'Cannot run the command as the ""%Couples1%"" subsystem is unavailable.';
							|it = 'Impossibile eseguire il comando, poiché il sotto sistema %Couples1% non è accessibile.';
							|pl = 'Wykonanie polecenia jest niemożliwe, ponieważ podsystem ""%Couples1%"" jest niedostępny.';
							|tr = '""%Couples1%"" alt sistemi kullanılamadığı için komut çalıştırılamıyor.'");
		 MessageText = StrReplace(MessageText, "%Couples1%", "MagneticCardReader");
		 Raise MessageText;
	EndIf;
	
EndFunction
 
#EndRegion

