
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	ReadOnly = Parameters.ReadOnly;
	DocumentType = Parameters.DocumentType;
	
	TypesArray = New Array;
	TypesArray.Add(Type(DocumentType));
	TypeDescription = New TypeDescription(TypesArray);
	
	AttributesArray = New Array();
	AttributesArray.Add(New FormAttribute("Object", TypeDescription));
	
	ChangeAttributes(AttributesArray);
	DocumentObject = ThisObject.Object; // DocumentObject
	DocumentObject.AdditionalAttributes.Load(GetFromTempStorage(Parameters.AddressInTempStorage));
	 
	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", DocumentObject);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	If ReadOnly Then
		TMCommonUseClientServer.SetFormItemProperty(Items, "GroupAdditionalAttributes", "ReadOnly", True);
	EndIf;
	
	DetailsAreMissing = (Items.GroupAdditionalAttributes.ChildItems.Count() = 0);
	Items.GroupDetailsAreMissing.Visible = DetailsAreMissing;
	Try
		StringMetadata = Common.TableNameByRef(DocumentObject.Ref);
		SetOfAdditionalBankingDetails = PropertyManager.PropertiesSetByName(StrReplace(StringMetadata,".","_"));
		
		Items.TitleGroup.Title = StringFunctionsClientServer.SubstituteParametersToString(
			"%1 ""%2""",
			Common.ObjectKindByRef(DocumentObject.Ref),
			DocumentObject.Ref.Metadata().Synonym);
	Except
		SetOfAdditionalBankingDetails = Undefined;
	EndTry; 
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText,  StandardProcessing)
	
	If ForceCloseTheForm Then
		Return;
	EndIf;
	
	If Modified And Not SaveParameters And Not Exit Then
		
		ButtonsList = New ValueList();
		ButtonsList.Add("Close", NStr("vi = 'Đóng';
										|ru = 'Закрыть';
										|en = 'Close'; fa = 'بستن';
										|it = 'Chiudere';
										|pl = 'Zamknij';
										|tr = 'Kapat'"));
		ButtonsList.Add("NotClose", NStr("vi = 'Không đóng';
										|ru = 'Не закрывать';
										|en = 'Do not close'; fa = 'بسته نشود';
										|it = 'Non chiudere';
										|pl = 'Nie zamykaj';
										|tr = 'Kapatmayın'"));
		
		AdditionalParameters = New Structure;
		Cancel = True;
		ShowQueryBox(
			New CallbackDescription("BeforeClosingQuestionEnds", ThisObject, AdditionalParameters),
			NStr("vi = 'Các chi tiết bổ sung đã được thay đổi. Đóng mà không lưu chi tiết?';
				|ru = 'Дополнительные реквизиты были изменены. Закрыть без сохранения реквизитов?';
				|en = 'Additional attributes were changed. Close without saving the attributes?'; fa = 'Additional attributes were changed. Close without saving the attributes?';
				|it = 'I requisiti aggiuntivi sono stati modificati. Chiudere senza salvare i requisiti?';
				|pl = 'Dodatkowe szczegóły zostały zmienione. Zamknij bez zapisywania szczegółów?';
				|tr = 'Ek öznitelikler değiştirilmiştir. Öznitelikler kaydedilmeden kapatılsın mı?'"),
			ButtonsList);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClosingQuestionEnds(UserAnswer, AdditionalAttributes) Export
	
	If UserAnswer = "NotClose" Then
		
		SaveParameters = False;
		
	Else
		
		ForceCloseTheForm = True;
		Close();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If SaveParameters And Not Exit Then
		
		SelectionResult = PlaceAdditionalDetailsInVault();
		NotifyChoice(SelectionResult);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	If Not ReadOnly Then
		SaveParameters = True;
	EndIf;
		
	Close();
	
EndProcedure

#EndRegion

#Region Private

// StandardSubsystems.Properties

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

// End StandardSubsystems.Properties

#Region Other

&AtServer
Function PlaceAdditionalDetailsInVault()
	
	// Handler of the "Properties" mechanism
	PropertyManager.BeforeWriteAtServer(ThisForm,  ThisForm["Object"]);
	
	GoodsAddressInStorage = PutToTempStorage(ThisForm["Object"].AdditionalAttributes.Unload(), UUID);
	Return New Structure("DocumentType,AdditionalAttributes", DocumentType, GoodsAddressInStorage);
	
EndFunction

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure
// End StandardSubsystems.Properties

&AtClient
Procedure ChangeSetOfAdditionalAttributes(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("ShowAdditionalAttributes");
	
	OpenForm("Catalog.AdditionalAttributesAndInfoSets.ListForm", FormParameters,,,,,
		//A new description of the announcement ("Formadprequisitovzakryvanie", this object)
		);
	
	MigrationParameters = New Structure("Set, Property, PropertyKind1, IsAdditionalInfo",
		SetOfAdditionalBankingDetails,
		Undefined,
		PredefinedValue("Enum.PropertiesKinds.AdditionalAttributes"),
		False);
	
	Notify("GoAdditionalDataAndAttributeSets", MigrationParameters);
	
	PropertyManagerClient.ExecuteCommand(ThisForm);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Handler of the "Properties" mechanism
	If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
	
EndProcedure

#EndRegion

#EndRegion
