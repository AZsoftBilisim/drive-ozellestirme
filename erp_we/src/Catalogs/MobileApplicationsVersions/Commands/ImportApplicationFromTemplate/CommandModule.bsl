#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	DownloadAppsFromTemplates();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
// Loads the application from the layouts stored in the configuration.
//
Procedure DownloadAppsFromTemplates()
	
	VersionsList = AppVersions();
	
	CallbackDescription = New CallbackDescription("DownloadAppsFromTemplatesCompletion", ThisObject);
	
	SelectedElement = Undefined;
	
	SelectionHeader = NStr("vi = 'Chọn ứng dụng để kết nhập';
							|ru = 'Выбор приложения для загрузки';
							|en = 'Select application to import'; fa = 'Select application to import';
							|it = 'Scelta dell''applicazione per il caricamento';
							|pl = 'Wybór aplikacji do pobrania';
							|tr = 'İndirim için uygulama seçimi'");
	
	VersionsList.ShowChooseItem(CallbackDescription, SelectionHeader, SelectedElement);
	
EndProcedure

&AtClient
Procedure DownloadAppsFromTemplatesCompletion(SelectionResult, AdditionalParameters) Export

	If SelectionResult <> Undefined Then
		LoadDataFromTemplate(SelectionResult.Value);
		NotifyChanged(Type("CatalogRef.MobileApplicationsVersions"));
	EndIf;
	
EndProcedure

&AtServer
// Generates and returns a list of values containing data about versions
// of mobile applications that can be loaded from layouts.
//
// Returns:
//  A list of values containing data about the versions of applications to download from layouts.
// 
Function AppVersions()
	
	Return Catalogs.MobileApplicationsVersions.DownloadVersions();
	
EndFunction

&AtServer
// Loads the application from the specified layout.
//
// Parameters:
//  Package name is the name of the layout containing the mobile app version data.
//
Procedure LoadDataFromTemplate(TemplateName)

	MobileApps.DownloadAppVersionFromTemplate(TemplateName);
	
EndProcedure

#EndRegion