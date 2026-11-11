
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Items.TipSettingsRichterman.Visible = GetFunctionalOption("UsePaymentByCards");
	
	CurrentCWPSettings = CurrentCWPSettings();
	
	If ValueIsFilled(CurrentCWPSettings) Then
		Items.OpenCWDSettings.Enabled = AccessRight("View", Metadata.Catalogs.CWPSettings);
	Else
		Items.OpenCWDSettings.Enabled = AccessRight("Insert", Metadata.Catalogs.CWPSettings);
	EndIf;
	
	If Parameters.NotToOutputError Then
		Items.Header.Visible = False;
		ThisObject.Title = NStr("vi = 'Tùy chỉnh thiết bị kết nối';
								|ru = 'Настройки подключаемого оборудования';
								|en = 'Connected equipment settings'; fa = 'تنظیمات تجهیزات متصل';
								|it = 'Impostazioni dell''attrezzatura collegabile';
								|pl = 'Ustawienia podłączanych urządzeń';
								|tr = 'Çevre birimleri ayarları'");
	EndIf; 
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OpenPeripherals(Command)
	
	EquipmentManagerClient.UpdateClientWorkplace();
	
	OpenForm("Catalog.Peripherals.ListForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure OpenCWDSettings(Command)
	
	If ValueIsFilled(CurrentCWPSettings) Then
		ShowValue(Undefined, CurrentCWPSettings);
	Else
		OpenForm("Catalog.CWPSettings.ObjectForm",,ThisForm);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Function CurrentCWPSettings()
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	CWPSettings.Ref
	|FROM
	|	Catalog.CWPSettings AS CWPSettings
	|WHERE
	|	CWPSettings.Workplace = &Workplace";

	Query.SetParameter("Workplace", EquipmentManagerServerCall.GetClientSWorkplace());

	Result = Query.Execute();
	Selection = Result.Select();

	If Selection.Next() Then
	
		Return Selection.Ref;
		
	Else
		
		Return Catalogs.CWPSettings.EmptyRef();
		
	EndIf;
	
EndFunction

#EndRegion