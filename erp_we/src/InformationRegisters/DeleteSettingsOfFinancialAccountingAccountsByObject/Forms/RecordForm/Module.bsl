
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
		MessageText = StrTemplate(NStr("vi = 'Cần điền trường ""Doanh nghiệp"" hoặc ""%1"".';
										|ru = 'Поле ""Организация"" или ""%1"" должно быть заполнено.';
										|en = 'The ""Company"" or ""%1"" field is required.'; fa = 'The ""Company"" or ""%1"" field is required.';
										|it = 'Поле ""Организация"" или ""%1"" должно быть заполнено.';
										|pl = 'Pole ""Firma"" lub ""%1"" powinno być wypełnione.';
										|tr = '""İş yeri"" veya ""%1"" alanı doldurulmalıdır.'"), Items.PlaceOfRegistration.Title);
		Common.MessageToUser(MessageText, , , , Cancel);
	ElsIf Items.Organization.Visible And Not ValueIsFilled(Record.Organization) And Not Items.PlaceOfRegistration.Visible Then
		Common.MessageToUser(
			NStr("vi = 'Cần điền trường ""Doanh nghiệp"".';
				|ru = 'Поле ""Организация"" должна быть заполнено.';
				|en = 'The ""Company"" field is required.'; fa = 'The ""Company"" field is required.';
				|it = 'Поле ""Организация"" должна быть заполнено.';
				|pl = 'Pole ""Firma"" powinno być wypełnione.';
				|tr = '""İş yeri"" alanı doldurulmalıdır.'"), ,  "Record.Organization", , Cancel);
	ElsIf Items.PlaceOfRegistration.Visible And Not ValueIsFilled(Record.PlaceOfRegistration) And Not Items.Organization.Visible Then
		MessageText = StrTemplate(NStr("vi = 'Cần điền trường ""%1"".';
										|ru = 'Поле ""%1"" должно быть заполнено.';
										|en = 'The ""%1"" field is required.'; fa = 'The ""%1"" field is required.';
										|it = 'Поле ""%1"" должно быть заполнено.';
										|pl = 'Pole ""%1"" powinno być wypełnione.';
										|tr = '""%1"" alanı doldurulmalıdır.'"), Items.PlaceOfRegistration.Title);
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
Procedure ObjectOfFinancialAccountingOnChange(Item)
	ObjectOfFinancialAccountingOnChangeServer();
EndProcedure

&AtClient
Procedure SettingTypeOnChange(Item)
	SettingTypeOnChangeServer();
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure OnReadCreateAtServer()
	DescriptionOfAccountingObjects.Load(Enums.DeleteFinancialAccountingObjects.ExtendedDescriptionOfAccountingObjectsToConfigure());
	FormControl()
EndProcedure

&AtServer
Procedure FormControl()
	
	SettingUpException = (Record.SettingType = Enums.TypesOfPostingsSettingsInFinancialAccounting.ExceptionForTheAccountingObject);
	
	Items.Organization.Visible = SettingUpException;
	
	Items.SettingType.ReadOnly = Parameters.DoNotChangeTheSettingType;
	Items.ObjectOfFinancialAccounting.ReadOnly = Parameters.DoNotChangeTheAccountingObject;
	
	AccountingObjectDescriptions = DescriptionOfAccountingObjects.FindRows(New Structure("AccountingObject", Record.AccountingObject));
	If AccountingObjectDescriptions.Count() > 0 Then
		DescriptionOfAccountingObject_ = AccountingObjectDescriptions[0];
		AllocationOfLongTermAssetsAndLiabilities = DescriptionOfAccountingObject_.AllocationOfLongTermAssetsAndLiabilities;
		ObjectOfAccountingForImproperValues = DescriptionOfAccountingObject_.ImproperValues;
		
		Items.SettingObject1.Visible = DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes.Types().Count() > 0;
		Items.SettingObject1.TypeRestriction = DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes;
		Items.SettingObject1.Title = Enums.DeleteFinancialAccountingObjects.TitleOfTypeDescriptionConfigurationObject(DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes);
		Items.SettingObject1.ChoiceParameters = Enums.DeleteFinancialAccountingObjects.ObjectSelectionParametersSetup(DescriptionOfAccountingObject_.SelectingConfigurationObjects);
		
		Items.PlaceOfRegistration.Visible = SettingUpException And DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes.Types().Count() > 0;
		Items.PlaceOfRegistration.TypeRestriction = DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes;
		Items.PlaceOfRegistration.Title = Enums.DeleteFinancialAccountingObjects.TitleOfAccountingLocation(DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes);
	Else
		AllocationOfLongTermAssetsAndLiabilities = False;
		Items.SettingObject1.Visible = False;
		Items.PlaceOfRegistration.Visible = False;
	EndIf;
	
	Items.Organization.AutoMarkIncomplete = Not Items.PlaceOfRegistration.Visible;
	Items.Organization.InputHint = ?(Items.PlaceOfRegistration.Visible, NStr("vi = 'Tất cả';
																			|ru = 'Все';
																			|en = 'All'; fa = 'همه';
																			|it = 'Все';
																			|pl = 'Wszystkie';
																			|tr = 'Tümü'"), "");
	
	Items.PlaceOfRegistration.AutoMarkIncomplete = Not Items.Organization.Visible;
	Items.PlaceOfRegistration.InputHint = ?(Items.Organization.Visible, NStr("vi = 'Tất cả';
																			|ru = 'Все';
																			|en = 'All'; fa = 'همه';
																			|it = 'Все';
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
																			|it = 'Краткосрочный';
																			|pl = 'Krótkoterminowy';
																			|tr = 'Kısa vadeli'"), "");
	
EndProcedure

&AtServer
Procedure ObjectOfFinancialAccountingOnChangeServer()
	
	AccountingObjectDescriptions = DescriptionOfAccountingObjects.FindRows(New Structure("AccountingObject", Record.AccountingObject));
	If AccountingObjectDescriptions.Count() > 0 Then
		DescriptionOfAccountingObject_ = AccountingObjectDescriptions[0];
		Record.PlaceOfRegistration = DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes.AdjustValue(Record.PlaceOfRegistration);
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

#EndRegion

