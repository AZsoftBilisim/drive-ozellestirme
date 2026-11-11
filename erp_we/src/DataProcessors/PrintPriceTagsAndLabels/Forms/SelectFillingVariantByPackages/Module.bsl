
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	UseBinLocationWarehousing = GetFunctionalOption("UseBinLocationWarehousing");
	If UseBinLocationWarehousing Then
		Items.Variant.ChoiceList.Add("ByWarehouseGroup_",
											NStr("vi = 'Theo nhóm đóng gói';
												|ru = 'По складской группе упаковок';
												|en = 'Warehouse packaging unit group'; fa = 'Warehouse packaging unit group';
												|it = 'Imballaggi per gruppo di magazzini';
												|pl = 'Według grupy magazynowej opakowań';
												|tr = 'Paketlerin depolama grubuna göre'"));
	EndIf;
	
	Items.WarehouseGroup.Visible = UseBinLocationWarehousing;
	
	Variant = Parameters.Variant;
	WarehouseGroup = Parameters.WarehouseGroup;
	If IsBlankString(Variant) Then
		Variant = "Optimal";
	EndIf;
	
	SetAccessibilityVisibilityOfBankingDetails();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure VariantOnChange(Item)
	SetAccessibilityVisibilityOfBankingDetails();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure FillInPackaging(Command)
	
	ClearMessages();
	CheckError = False;
	MessageTemplate = NStr("vi = 'Chưa điền trường ""%FieldName%"".';
							|ru = 'Поле ""%FieldName%"" не заполнено.';
							|en = '""%FieldName%"" is required.'; fa = '""%FieldName%"" is required.';
							|it = 'Il campo ""%FieldName%"" non è compilato.';
							|pl = 'Nie wypełniono pola ""%FieldName%"".';
							|tr = '""%FieldName%"" alanı doldurulmamış.'");
	
	If Variant = "ByWarehouseGroup_" Then
		
		If Not ValueIsFilled(WarehouseGroup) Then
			MessageText = StrReplace(MessageTemplate,"%FieldName%",NStr("vi = 'Nhóm kho';
																		|ru = 'Складская группа';
																		|en = 'Warehouse group'; fa = 'گروه انبار';
																		|it = 'Gruppo di magazzini';
																		|pl = 'Grupa magazynowa';
																		|tr = 'Ambar grubu'"));
			CommonClient.MessageToUser(MessageText,,"WarehouseGroup");
			CheckError = True;
		EndIf;
		
	EndIf;
	
	If CheckError Then
		Return;
	EndIf;
	
	Close(New Structure("Variant, WarehouseGroup", Variant, WarehouseGroup));
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetAccessibilityVisibilityOfBankingDetails()
	
	Items.WarehouseGroup.Enabled = (Variant = "ByWarehouseGroup_");
	
EndProcedure

#EndRegion
