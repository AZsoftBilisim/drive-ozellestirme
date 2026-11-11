#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	TypeOfLocation = Parameters.LocationTypeOfExternalURLHostAddress;
	If Not ValueIsFilled(TypeOfLocation) Then
		TypeOfLocation = Enums.InfobaseLocationType.OnWebServer;
	EndIf;
	
	If TypeOfLocation = Enums.InfobaseLocationType.OnWebServer Then
		WebServiceAddress = Parameters.ExternalURLHostAddress;
		
	ElsIf TypeOfLocation = Enums.InfobaseLocationType.At1CEnterpriseServer Then
		SeparatorLocation = StrFind(Parameters.ExternalURLHostAddress, "/");
		If SeparatorLocation = 0 Then
			InfobaseName = Parameters.ExternalURLHostAddress;
		Else
			IClusterInfo = Left(Parameters.ExternalURLHostAddress, SeparatorLocation - 1);
			InfobaseName = Mid(Parameters.ExternalURLHostAddress, SeparatorLocation + 1);
		EndIf;
		
	ElsIf TypeOfLocation = Enums.InfobaseLocationType.OnLANComputer Then
		NetworkDirectory = Parameters.ExternalURLHostAddress;
		NetworkDirectory = StrReplace(NetworkDirectory, "/", "\");
		NetworkDirectory = "\\" + NetworkDirectory;
		
	ElsIf TypeOfLocation = Enums.InfobaseLocationType.OnThisComputer Then
		LocalDirectory = Parameters.ExternalURLHostAddress;
		LocalDirectory = StrReplace(LocalDirectory, "/", "\");
		Disk = Left(LocalDirectory, 1);
		Path = Mid(LocalDirectory, 3);
		LocalDirectory = Disk + ":\" + Path;
		
	EndIf;
	
	If Not ValueIsFilled(WebServiceAddress) Then
		If ValueIsFilled(Parameters.WebServiceAddress) Then
			WebServiceAddress = Parameters.WebServiceAddress;
		Else
			WebServiceAddress = IntegrationWith1CDocumentManagementCore.AddressOf1CDocumentManagementWebService(
				True);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	BeginGettingDocumentsDir(New CallbackDescription("GettingDocumentCatalogEnd", ThisObject));
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure WebServiceAddressOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If Not ValueIsFilled(WebServiceAddress) Then
		Return;
	EndIf;
	
	IntegrationWith1CDocumentManagement3Client.OpenDMObject(
		"e1cib/command/DataProcessor.SeamlessIntegrationAdministrationPanel.Command.IntegrationSettings",
		WebServiceAddress);
	
EndProcedure

&AtClient
Procedure WebServiceAddressOnChange(Item)
	
	TypeOfLocation = PredefinedValue("Enum.InfobaseLocationType.OnWebServer");
	
EndProcedure

&AtClient
Procedure InfobaseNameOnChange(Item)
	
	TypeOfLocation = PredefinedValue("Enum.InfobaseLocationType.At1CEnterpriseServer");
	
EndProcedure

&AtClient
Procedure IClusterInfoOnChange(Item)
	
	TypeOfLocation = PredefinedValue("Enum.InfobaseLocationType.At1CEnterpriseServer");
	
EndProcedure

&AtClient
Procedure LocalDirectoryStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	
	FolderSelectionDialog = New FileDialog(FileDialogMode.ChooseDirectory);
	If IsBlankString(LocalDirectory) Then
		FolderSelectionDialog.Directory = DocumentsDir;
	Else
		FolderSelectionDialog.Directory = LocalDirectory;
	EndIf;
	
	ChoiceDialogNotificationDetails = New CallbackDescription(
		"ChooseDirectoryCompletion",
		ThisObject,
		PredefinedValue("Enum.InfobaseLocationType.OnThisComputer"));
	FileSystemClient.ShowSelectionDialog(ChoiceDialogNotificationDetails, FolderSelectionDialog);
	
EndProcedure

&AtClient
Procedure LocalDirectoryOnChange(Item)
	
	TypeOfLocation = PredefinedValue("Enum.InfobaseLocationType.OnThisComputer");
	
EndProcedure

&AtClient
Procedure NetworkDirectoryStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	
	FolderSelectionDialog = New FileDialog(FileDialogMode.ChooseDirectory);
	If IsBlankString(NetworkDirectory) Then
		FolderSelectionDialog.Directory = DocumentsDir;
	Else
		FolderSelectionDialog.Directory = NetworkDirectory;
	EndIf;
	
	ChoiceDialogNotificationDetails = New CallbackDescription(
		"ChooseDirectoryCompletion",
		ThisObject,
		PredefinedValue("Enum.InfobaseLocationType.OnLANComputer"));
	FileSystemClient.ShowSelectionDialog(ChoiceDialogNotificationDetails, FolderSelectionDialog);
	
EndProcedure

&AtClient
Procedure NetworkDirectoryOnChange(Item)
	
	TypeOfLocation = PredefinedValue("Enum.InfobaseLocationType.OnLANComputer");
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OkCommand(Command)
	
	ClearMessages();
	
	Result = New Structure("ExternalURLHostAddress");
	Result.Insert("LocationTypeOfExternalURLHostAddress", TypeOfLocation);
	
	Cancel = False;
	
	If TypeOfLocation = PredefinedValue("Enum.InfobaseLocationType.OnWebServer") Then
		If Not ValueIsFilled(WebServiceAddress) Then
			CommonClient.MessageToUser(
				NStr("vi = 'Cần chỉ định địa chỉ cơ sở thông tin trên web-server';
					|ru = 'Требуется указать адрес информационной базы на веб-сервере';
					|en = 'Specify the infobase address on the web server'; fa = 'Specify the infobase address on the web server';
					|it = 'Требуется указать адрес информационной базы на веб-сервере';
					|pl = 'Specify the infobase address on the web server';
					|tr = 'Web sunucusunda infobase adresi belirtilmelidir'"),,
				"WebServiceAddress",,
				Cancel);
		Else
			Result.ExternalURLHostAddress = WebServiceAddress;
		EndIf;
		
	ElsIf TypeOfLocation =
			PredefinedValue("Enum.InfobaseLocationType.At1CEnterpriseServer") Then
		If Not ValueIsFilled(IClusterInfo) Then
			CommonClient.MessageToUser(
				NStr("vi = 'Cần chỉ ra cluster server mà trên đó đặt cơ sở thông tin';
					|ru = 'Требуется указать кластер серверов, на котором расположена информационная база';
					|en = 'Specify the server cluster where the infobase is located'; fa = 'Specify the server cluster where the infobase is located';
					|it = 'Требуется указать кластер серверов, на котором расположена информационная база';
					|pl = 'Specify the server cluster where the infobase is located';
					|tr = 'Infobase''in bulunduğu sunucu kümesi belirtilmelidir'"),,
				"IClusterInfo",,
				Cancel);
		EndIf;
		If Not ValueIsFilled(InfobaseName) Then
			CommonClient.MessageToUser(
				NStr("vi = 'Cần chỉ định tên cơ sở thông tin trên server';
					|ru = 'Требуется указать имя информационной базы на сервере';
					|en = 'Specify the infobase name on the server'; fa = 'Specify the infobase name on the server';
					|it = 'Требуется указать имя информационной базы на сервере';
					|pl = 'Specify the infobase name on the server';
					|tr = 'Sunucudaki infobase''in adının belirtilmesi gerekmektedir'"),,
				"InfobaseName",,
				Cancel);
		EndIf;
		If Not Cancel Then
			Result.ExternalURLHostAddress = IClusterInfo + "/" + InfobaseName;
		EndIf;
		
	ElsIf TypeOfLocation =
			PredefinedValue("Enum.InfobaseLocationType.OnLANComputer") Then
		If Not ThisIsNetworkDirectory(NetworkDirectory) Then
			CommonClient.MessageToUser(
				NStr("vi = 'Cần chỉ định thư mục trên mạng';
					|ru = 'Требуется указать сетевой каталог';
					|en = 'Specify the network directory'; fa = 'Specify the network directory';
					|it = 'Требуется указать сетевой каталог';
					|pl = 'Specify the network directory';
					|tr = 'Ağ dizini belirtilmelidir'"),,
				"NetworkDirectory",,
				Cancel);
		Else
			Result.ExternalURLHostAddress = Mid(NetworkDirectory, 3);
			Result.ExternalURLHostAddress =
				StrReplace(Result.ExternalURLHostAddress, "\", "/");
		EndIf;
		
	ElsIf TypeOfLocation =
			PredefinedValue("Enum.InfobaseLocationType.OnThisComputer") Then
		If Not ThisIsLocalDirectory(LocalDirectory) Then
			CommonClient.MessageToUser(
				NStr("vi = 'Cần chỉ định thư mục trên máy tính này';
					|ru = 'Требуется указать каталог на данном компьютере';
					|en = 'Specify the directory on this computer'; fa = 'Specify the directory on this computer';
					|it = 'Требуется указать каталог на данном компьютере';
					|pl = 'Specify the directory on this computer';
					|tr = 'Bu bilgisayarda bir dizin belirtilmelidir'"),,
				"LocalDirectory",,
				Cancel);
		Else
			Disk = Left(LocalDirectory, 1);
			Path = StrReplace(Mid(LocalDirectory, 4), "\", "/");
			Result.ExternalURLHostAddress = Disk + "/" + Path;
		EndIf;
		
	EndIf;
	
	If Not Cancel Then
		Close(Result);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ChooseDirectoryCompletion(SelectedDirectories, NewTypeOfLocation) Export
	
	If TypeOf(SelectedDirectories) = Type("Array") And SelectedDirectories.Count() > 0 Then
		If NewTypeOfLocation = PredefinedValue("Enum.InfobaseLocationType.OnThisComputer") Then
			If ThisIsLocalDirectory(SelectedDirectories[0]) Then
				LocalDirectory = SelectedDirectories[0];
				TypeOfLocation = NewTypeOfLocation;
			Else
				ShowMessageBox(, NStr("vi = 'Cần chỉ định thư mục trên máy tính này';
										|ru = 'Требуется указать каталог на данном компьютере';
										|en = 'Specify the directory on this computer'; fa = 'Specify the directory on this computer';
										|it = 'Требуется указать каталог на данном компьютере';
										|pl = 'Specify the directory on this computer';
										|tr = 'Bu bilgisayarda bir dizin belirtilmelidir'"));
			EndIf;
		ElsIf NewTypeOfLocation = PredefinedValue("Enum.InfobaseLocationType.OnLANComputer") Then
			If ThisIsNetworkDirectory(SelectedDirectories[0]) Then
				NetworkDirectory = SelectedDirectories[0];
				TypeOfLocation = NewTypeOfLocation;
			Else
				ShowMessageBox(, NStr("vi = 'Cần chỉ định thư mục trên mạng';
										|ru = 'Требуется указать сетевой каталог';
										|en = 'Specify the network directory'; fa = 'Specify the network directory';
										|it = 'Требуется указать сетевой каталог';
										|pl = 'Specify the network directory';
										|tr = 'Ağ dizini belirtilmelidir'"));
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure GettingDocumentCatalogEnd(Result, NotificationParameters) Export
	
	DocumentsDir = Result;
	Items.LocalDirectory.InputHint = DocumentsDir + "InfoBase";
	
EndProcedure

&AtClient
Function ThisIsLocalDirectory(Directory)
	
	Return (Mid(Directory, 2, 2) = ":\");
	
EndFunction

&AtClient
Function ThisIsNetworkDirectory(Directory)
	
	Return (Left(Directory, 2) = "\\");
	
EndFunction

#EndRegion