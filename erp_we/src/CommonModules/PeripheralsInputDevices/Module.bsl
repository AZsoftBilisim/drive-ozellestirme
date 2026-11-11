
#Region Internal

// Adds the supplied drivers to the list as part of the configuration.
//
// Parameters:
//  DriversOfHardware - See EquipmentManager.NewTableOfSuppliedHardwareDrivers
//
Procedure UpdateSuppliedDrivers(DriversOfHardware) Export
	
	Driver = DriversOfHardware.Add();
	Driver.EquipmentType = Enums.PeripheralTypes.BarcodeScanner;
	Driver.NameOfDriver  = "Driver1CBarcodeScannersNative";
	Driver.Description = NStr("vi = '1C:Barcode scanners (Native API)';
								|ru = '1С:Сканеры штрихкода (Native Api)';
								|en = '1C:Barcode scanners (Native Api)'; fa = '1C:Barcode scanners (Native Api)';
								|it = '1C:Scanner del codice a barre (Native Api)';
								|pl = '1C:Skanery kodów kreskowych (Native Api)';
								|tr = '1C:Barcode scanners (Native Api)'", CommonCEL.DefaultLanguageCode());
	Driver.ObjectID = "InputDevice"; 
	Driver.DriverTemplateName = "Driver1CInputDevicesNative";   
	Driver.RecommendedUse = True;
	
	// ++ Non-mobile application
	Driver = DriversOfHardware.Add();
	Driver.EquipmentType = Enums.PeripheralTypes.MagneticStripeCardReaders;
	Driver.NameOfDriver  = "Driver1CNativeMagneticCardReaders";
	Driver.Description = NStr("vi = '1C:Magnetic card readers (Native Api)';
								|ru = '1С:Считыватели магнитных карт (Native Api)';
								|en = '1C:Magnetic stripe card readers (Native Api)'; fa = '1C:Magnetic stripe card readers (Native Api)';
								|it = '1C:Lettori di carte magnetiche (Native Api)';
								|pl = '1C:Czytniki kart magnetycznych (Native Api)';
								|tr = '1C:Magnetic stripe card readers (Native Api)'", CommonCEL.DefaultLanguageCode());
	Driver.ObjectID = "InputDevice"; 
	Driver.DriverTemplateName = "Driver1CInputDevicesNative";  
	Driver.RecommendedUse = True;
	// -- Non-mobile application 
	
EndProcedure

#EndRegion