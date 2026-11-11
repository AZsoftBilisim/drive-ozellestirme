
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Var ParametersOfMovementOfGoods;
	
	If Not Parameters.Property("ParametersOfMovementOfGoods", ParametersOfMovementOfGoods) Or TypeOf(ParametersOfMovementOfGoods) <> Type("Structure") Then
		
		Template = NStr("vi = 'Chưa chuyển tham số dịch vụ %Couples1%';
						|ru = 'Не передан служебный параметр %Couples1%';
						|en = 'Internal parameter %Couples1% is not passed'; fa = 'Internal parameter %Couples1% is not passed';
						|it = 'Il parametro di servizio %Couples1% non è stato trasmesso';
						|pl = 'Nie przekazano parametru serwisowego %Couples1%';
						|tr = '%Couples1% servis parametresi iletilmedi'");
		
		Template = StrReplace(Template, "%Couples1%", "ParametersOfMovementOfGoods");
		
		Raise Template;
		
	EndIf;
	
	If Not ParametersOfMovementOfGoods.Property("RegistrationOption", RegistrationOption) Then
		
		RegistrationOption = Enums.OptionsOfRegisteringTransferDocuments.InventoryTransfer;
		
	EndIf;
	
	If Not ParametersOfMovementOfGoods.Property("OnlyInStock", OnlyInStock) Then
		
		OnlyInStock = True;
		
	EndIf;
	
	CustomizeFormElements();
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure RegistrationOptionOnChange(Item)
	
	OnlyInStock = ?(RegistrationOption = PredefinedValue("Enum.OptionsOfRegisteringTransferDocuments.InventoryTransfer"), True, OnlyInStock);
	ConfigureDependentFormElements(ThisForm, "RegistrationOption");
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Apply(Command)
	
	Result = New Structure();
	
	ParametersOfMovementOfGoods = New Structure("RegistrationOption, OnlyInStock", RegistrationOption, OnlyInStock);
	Result.Insert("ParametersOfMovementOfGoods", ParametersOfMovementOfGoods);
	
	Close(Result);
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtServer
Procedure CustomizeFormElements()
	
	ConfigureDependentFormElements(ThisForm);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Items = Form.Items;

	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	If AttributesStructure1.Property("RegistrationOption")
		Or Initialize Then
		Items.OnlyInStock.Enabled = Form.RegistrationOption = PredefinedValue("Enum.OptionsOfRegisteringTransferDocuments.TransferOrder");
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
