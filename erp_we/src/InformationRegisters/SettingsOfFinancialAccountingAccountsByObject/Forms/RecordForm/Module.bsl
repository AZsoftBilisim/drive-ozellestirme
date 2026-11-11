
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Not ValueIsFilled(Record.SourceRecordKey) Then
		OnReadCreateAtServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	OnReadCreateAtServer();
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If Items.Organization.Visible And Not ValueIsFilled(Record.Organization)
		And Items.PlaceOfRegistration.Visible And Not ValueIsFilled(Record.PlaceOfRegistration) Then
		MessageText = StrTemplate(NStr("vi = 'Trường ""Doanh nghiệp"" hoặc ""%1"" cần được điền.';
										|ru = 'Поле ""Организация"" или ""%1"" должно быть заполнено.';
										|en = 'The ""Company"" or ""%1"" field is required.'; fa = 'The ""Company"" or ""%1"" field is required.';
										|it = 'Campo ""Azienda"" o ""%1"" deve essere compilato.';
										|pl = 'Pole ""Firma"" lub ""%1"" powinno być wypełnione.';
										|tr = '""İş yeri"" veya ""''%1"" alanı doldurulmalıdır.'"), Items.PlaceOfRegistration.Title);
		Common.MessageToUser(MessageText, , , , Cancel);
	ElsIf Items.Organization.Visible And Not ValueIsFilled(Record.Organization) And Not Items.PlaceOfRegistration.Visible Then
		Common.MessageToUser(
			NStr("vi = 'Trường ""Doanh nghiệp"" cần được điền.';
				|ru = 'Поле ""Организация"" должна быть заполнено.';
				|en = 'The ""Company"" field is required.'; fa = 'The ""Company"" field is required.';
				|it = 'Campo ""Azienda"" deve essere compilato.';
				|pl = 'Pole ""Firma"" powinno być wypełnione.';
				|tr = '""İş yeri"" alanı doldurulmalıdır.'"), ,  "Record.Organization", , Cancel);
	ElsIf Items.PlaceOfRegistration.Visible And Not ValueIsFilled(Record.PlaceOfRegistration) And Not Items.Organization.Visible Then
		MessageText = StrTemplate(NStr("vi = 'Trường ""%1"" cần được điền.';
										|ru = 'Поле ""%1"" должно быть заполнено.';
										|en = 'The ""%1"" field is required.'; fa = 'The ""%1"" field is required.';
										|it = 'Campo ""%1"" deve essere compilato.';
										|pl = 'Pole ""%1"" powinno być wypełnione.';
										|tr = '""''%1"" alanı doldurulmalıdır.'"), Items.PlaceOfRegistration.Title);
		Common.MessageToUser(MessageText, , "Record.PlaceOfRegistration", , Cancel);
	EndIf;

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	Notify("Write_SettingsOfFinancialAccountingAccountsByObject");
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AccountingObjectOnChange(Item)
	AccountingObjectOnChangeServer();
EndProcedure

&AtClient
Procedure SettingTypeOnChange(Item)
	SettingTypeOnChangeServer();
EndProcedure

&AtClient
Procedure SettingObject1StartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	
	FullFormName = SettingObjectSource + "." + "ChoiceForm";
	FormParameters = New Structure();
	FormParameters.Insert("FixedSettings", SettingsComposerObjectSettings.Settings);
	
	OpenForm(FullFormName, FormParameters, Item);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure OnReadCreateAtServer()
	GetDescriptionOfAccountingObject();
	FormControl()
EndProcedure

&AtServer
Procedure FormControl()
	
	SettingUpException = (Record.SettingType = Enums.TypesOfPostingsSettingsInFinancialAccounting.ExceptionForTheAccountingObject);
	
	Items.Organization.Visible = SettingUpException;
	
	Items.SettingType.ReadOnly = Parameters.DoNotChangeTheSettingType;
	Items.AccountingObject.ReadOnly = Parameters.DoNotChangeTheAccountingObject;
	
	If DescriptionOfAccountingObject_ <> Undefined Then
		AllocationOfLongTermAssetsAndLiabilities = DescriptionOfAccountingObject_.AllocationOfLongTermAssetsAndLiabilities;
		ImproperValues = DescriptionOfAccountingObject_.ImproperValues;
		
		Items.SettingObject1.Visible = DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes.Types().Count() > 0;
		Items.SettingObject1.TypeRestriction = DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes;
		Items.SettingObject1.Title = ChartsOfCharacteristicTypes.AssetLiabilityItems.ItemTitleByTypeDescription(
			DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes);
		
		Items.PlaceOfRegistration.Visible = SettingUpException And DescriptionOfAccountingObject_.DescriptionOfTypesOfDetailedSettings.Types().Count() > 0;
		Items.PlaceOfRegistration.TypeRestriction = DescriptionOfAccountingObject_.DescriptionOfTypesOfDetailedSettings;
		Items.PlaceOfRegistration.Title = ChartsOfCharacteristicTypes.AssetLiabilityItems.ItemTitleByTypeDescription(
			DescriptionOfAccountingObject_.DescriptionOfTypesOfDetailedSettings);
		
		SettingsComposerObjectSettings.Initialize(Undefined);
		SettingsComposerObjectSettings.Settings.Filter.Items.Clear();
		
		If DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes.Types().Count() > 0 Then
			TypeOfConfigurationObject = DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes.Types()[0];
			MetadataConfigurationObject = Metadata.FindByType(TypeOfConfigurationObject);
			SettingObjectSource = MetadataConfigurationObject.FullName();
			
			ChartsOfCharacteristicTypes.AssetLiabilityItems.InitializeSettingsComposerWithSettingsObject(
				SettingsComposerObjectSettings,
				SettingObjectSource,
				MetadataConfigurationObject,
				UUID);
			
			FinancialAccountingByBalanceSheetRegisterData.CopyDataCompositionFilter(
				SettingsComposerObjectSettings.Settings.Filter,
				DescriptionOfAccountingObject_.SelectingConfigurationObjects);
		EndIf;
	Else
		AllocationOfLongTermAssetsAndLiabilities = False;
		Items.SettingObject1.Visible = False;
		Items.PlaceOfRegistration.Visible = False;
	EndIf;
	
	Items.Organization.AutoMarkIncomplete = Not Items.PlaceOfRegistration.Visible;
	Items.Organization.InputHint = ?(Items.PlaceOfRegistration.Visible, NStr("vi = 'Tất cả';
																			|ru = 'Все';
																			|en = 'All'; fa = 'همه';
																			|it = 'Tutti';
																			|pl = 'Wszystkie';
																			|tr = 'Tümü'"), "");
	
	Items.PlaceOfRegistration.AutoMarkIncomplete = Not Items.Organization.Visible;
	Items.PlaceOfRegistration.InputHint = ?(Items.Organization.Visible, NStr("vi = 'Tất cả';
																			|ru = 'Все';
																			|en = 'All'; fa = 'همه';
																			|it = 'Tutti';
																			|pl = 'Wszystkie';
																			|tr = 'Tümü'"), "");
	
	If Not AllocationOfLongTermAssetsAndLiabilities Then
	ElsIf Not ValueIsFilled(Record.PostingGenerationSetting) Then
		AllocationOfLongTermAssetsAndLiabilities = False;
	Else
		AllocationOfLongTermAssetsAndLiabilities = Common.ObjectAttributeValue(
			Record.PostingGenerationSetting, "DivisionIntoShortTermLongTermAssetsAndLiabilities");
	EndIf;
	
	Items.AccountingAccountGroup.ShowTitle = AllocationOfLongTermAssetsAndLiabilities;
	Items.LedgerAccountLongTerm.Visible = AllocationOfLongTermAssetsAndLiabilities;
	Items.GLAccount.Title = ?(AllocationOfLongTermAssetsAndLiabilities, NStr("vi = 'Ngắn hạn';
																			|ru = 'Краткосрочный';
																			|en = 'Short-term'; fa = 'کوتاه‌مدت';
																			|it = 'A breve termine';
																			|pl = 'Krótkoterminowy';
																			|tr = 'Kısa vadeli'"), "");
	
EndProcedure

&AtServer
Procedure AccountingObjectOnChangeServer()
	
	GetDescriptionOfAccountingObject();
	
	If DescriptionOfAccountingObject_ <> Undefined Then
		Record.SettingObject1 = DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes.AdjustValue(Record.SettingObject1);
		
		If Record.SettingType = Enums.TypesOfPostingsSettingsInFinancialAccounting.ExceptionForTheAccountingObject Then
			Record.PlaceOfRegistration = DescriptionOfAccountingObject_.DescriptionOfTypesOfDetailedSettings.AdjustValue(Record.PlaceOfRegistration);
		EndIf;
	EndIf;
	
	FormControl();
	
EndProcedure

&AtServer
Procedure SettingTypeOnChangeServer()
	If Record.SettingType <> Enums.TypesOfPostingsSettingsInFinancialAccounting.ExceptionForTheAccountingObject Then
		Record.Organization = Undefined;
		Record.PlaceOfRegistration = Undefined;
	EndIf;
	FormControl();
EndProcedure

&AtServer
Procedure GetDescriptionOfAccountingObject()
	
	If ValueIsFilled(Record.AccountingObject) Then
		DescriptionOfAccountingObject_ = ChartsOfCharacteristicTypes.AssetLiabilityItems.DescriptionOfFinancialAccountingObject(
			Record.AccountingObject, True);
	Else
		DescriptionOfAccountingObject_ = Undefined;
	EndIf;
	
EndProcedure

#EndRegion

