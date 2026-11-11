#Region Internal

// Returns: 
//  String - Warning text about active extensions that change the data structure
Function WarningTextAboutActiveExtensionsThatChangeDataStructure() Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	ActiveExtensionsThatChangeDataStructure = CommonCTL.ActiveExtensionsThatChangeDataStructure();

	If Not ValueIsFilled(ActiveExtensionsThatChangeDataStructure) Then
		Return "";
	EndIf;

	PartsOfWarningText = New Array;
	PartsOfWarningText.Add(
		NStr("vi = 'Trong ứng dụng đã thiết lập và kích hoạt phần mở rộng cấu hình làm thay đổi cấu trúc dữ liệu:';
			|ru = 'В приложении установлены и активны расширения конфигурации, изменяющие структуру данных:';
			|en = 'Configuration extensions that change the data structure are installed and active in the application:'; fa = 'Configuration extensions that change the data structure are installed and active in the application:';
			|it = 'Nell''applicazione sono installate e abilitate le estensioni della configurazione che modificano la struttura dei dati:';
			|pl = 'W aplikacji są zainstalowane rozszerzenia konfiguracji, zmieniające strukturę danych:';
			|tr = 'Veri yapısını değiştiren yapılandırma uzantıları uygulamada yüklü ve aktiftir:'"));

	PartsOfWarningText.Add(Chars.LF);
	PartsOfWarningText.Add(Chars.LF);
	
	For Each Extension In ActiveExtensionsThatChangeDataStructure Do
		PartsOfWarningText.Add("● ");
		PartsOfWarningText.Add(Extension.Synonym);
		PartsOfWarningText.Add(Chars.LF);
	EndDo;
	
	Return StrConcat(PartsOfWarningText);		
		
EndFunction

// The download is interrupted
// 
// Returns:
//  Boolean
Function DownloadAborted() Export
	If Not SaaSOperations.SeparatedDataUsageAvailable() Then
		Return False;
	EndIf;	
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	Return ExportImportDataInternal.DownloadAborted();
EndFunction
	
#EndRegion