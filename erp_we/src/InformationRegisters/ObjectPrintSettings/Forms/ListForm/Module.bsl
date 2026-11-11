
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	FillInObjectPrintingSettings();
	
	If Not UserRightsCached.AddEditObjectPrintSettings()
	 And Not UserRightsCached.SaveObjectPrintSettingsByDefault() Then
		Items.ObjectPrintSettingsAdd.Visible = False;
		Items.ObjectPrintSettingsDelete.Visible  = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_ObjectPrintSettings" Then
		FillInObjectPrintingSettings();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersObjectPrintSettings

&AtClient
Procedure ObjectPrintSettingsSelection(Item, RowSelected, Field, StandardProcessing)
	
	Var RecordKey;
	
	If Item.CurrentItem = Items.ObjectPrintSettingsPresentation And
		Items.ObjectPrintSettings.CurrentData <> Undefined And 
		Items.ObjectPrintSettings.CurrentData.PictureIndex = 0 Then
		
		StandardProcessing = False;
		
		ObjectType  = "";
		Organization = PredefinedValue("Catalog.Companies.EmptyRef");
		Partner     = PredefinedValue("Catalog.Partners.EmptyRef");
		
		CurrentData = Items.ObjectPrintSettings.CurrentData;
		
		If TypeOf(CurrentData.Setting) = Type("String") Then
			ObjectType = CurrentData.Setting;
		ElsIf TypeOf(CurrentData.Setting) = Type("CatalogRef.Companies") Then
			ObjectType  = CurrentData.GetParent().Setting;
			Organization = CurrentData.Setting;
		ElsIf TypeOf(CurrentData.Setting) = Type("CatalogRef.Partners") Then
			ObjectType  = CurrentData.GetParent().GetParent().Setting;
			Organization = CurrentData.GetParent().Setting;
			Partner     = CurrentData.Setting;
		EndIf;
		
		RecordKeyData = New Structure();
		RecordKeyData.Insert("ObjectType",  ObjectType);
		RecordKeyData.Insert("Organization", Organization);
		RecordKeyData.Insert("Partner",     Partner);
		
		If RecordExists(RecordKeyData) Then
			ArrayOfConstructorParameters = New Array();
			ArrayOfConstructorParameters.Add(RecordKeyData);
			
			RecordKey = New("InformationRegisterRecordKey.ObjectPrintSettings", ArrayOfConstructorParameters);
		EndIf;
		
		OpenForm(
			"InformationRegister.ObjectPrintSettings.RecordForm",
			New Structure("Key,FillingValues",
			RecordKey, RecordKeyData),,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Add(Command)
	
	OpenForm("InformationRegister.ObjectPrintSettings.RecordForm",,,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure Delete(Command)
	
	CurrentData = Items.ObjectPrintSettings.CurrentData;
	
	If CurrentData = Undefined Then
		ShowMessageBox(Undefined, NStr("vi = 'Hãy chỉ ra tùy chỉnh in để xóa bỏ';
										|ru = 'Укажите настройку печати для удаления';
										|en = 'Specify a print option to delete'; fa = 'Specify a print option to delete';
										|it = 'Indica un''impostazione di stampa da eliminare';
										|pl = 'Określ ustawienie drukowania do usunięcia';
										|tr = 'Silme için yazdırma ayarı belirt'"));
		Return;
	EndIf;
	
	If CurrentData.PictureIndex = 1 Then
		ShowMessageBox(Undefined, NStr("vi = 'Không thể xóa gom nhóm';
										|ru = 'Невозможно удалить группировку';
										|en = 'You cannot remove grouping'; fa = 'You cannot remove grouping';
										|it = 'Impossibile eliminare il raggruppamento';
										|pl = 'Nie można usunąć grupowania';
										|tr = 'Gruplama silinemiyor'"));
		Return;
	EndIf;
	
	ButtonsList = New ValueList();
	ButtonsList.Add("Delete", NStr("vi = 'Xóa bỏ';
									|ru = 'Удалить';
									|en = 'Delete'; fa = 'حذف';
									|it = 'Eliminare';
									|pl = 'Delete';
									|tr = 'Sil'"));
	ButtonsList.Add("NotShouldDelete", NStr("vi = 'Không xóa';
											|ru = 'Не удалять';
											|en = 'Do not delete'; fa = 'حذف نشود';
											|it = 'Non eliminare';
											|pl = 'Nie usuwaj';
											|tr = 'Silme'"));
	
	UserAnswer = Undefined;

	
	ShowQueryBox(New CallbackDescription("DeleteCompletion", ThisObject, New Structure("CurrentData", CurrentData)), NStr("vi = 'Xóa bỏ tùy chỉnh in?';
																															|ru = 'Удалить настройку печати?';
																															|en = 'Remove print setup?'; fa = 'Remove print setup?';
																															|it = 'Eliminare l''impostazione di stampa?';
																															|pl = 'Usunąć ustawienie drukowania?';
																															|tr = 'Yazdırma ayarını sil?'"), ButtonsList);
	
EndProcedure

&AtClient
Procedure DeleteCompletion(QuestionResult, AdditionalParameters) Export
    
    CurrentData = AdditionalParameters.CurrentData;
    
    
    UserAnswer = QuestionResult;
    
    If UserAnswer = "NotShouldDelete" Then
        Return;
    EndIf;
    
    ClearMessages();
    RemovePrintServerSetting(CurrentData.GetID());

EndProcedure

&AtClient
Procedure Refresh(Command)
	
	FillInObjectPrintingSettings();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillInObjectPrintingSettings()
	
	Query = New Query("
	|SELECT
	|	ObjectPrintSettings.ObjectType  AS ObjectType,
	|	ObjectPrintSettings.Organization AS Organization,
	|	ObjectPrintSettings.Partner     AS Partner
	|FROM
	|	InformationRegister.ObjectPrintSettings AS ObjectPrintSettings
	|ORDER BY
	|	ObjectType,
	|	Organization,
	|	Partner
	|TOTALS BY
	|	ObjectType,
	|	Organization,
	|	Partner");
	
	QueryResult = Query.Execute();
	ObjectPrintSettings.GetItems().Clear();
	ValueTree = FormAttributeToValue("ObjectPrintSettings");
	
	If Not QueryResult.IsEmpty() Then
		
		ObjectTypeSelection = QueryResult.Select(QueryResultIteration.ByGroups);
		
		While ObjectTypeSelection.Next() Do
			
			ObjectTypeString = ValueTree.Rows.Add();
			ObjectTypeString.Setting = ObjectTypeSelection.ObjectType;
			ObjectTypeString.Presentation = Metadata.FindByFullName(ObjectTypeSelection.ObjectType).Presentation();
			ObjectTypeString.PictureIndex = 1;
			
			SampleOrganization = ObjectTypeSelection.Select(QueryResultIteration.ByGroups);
			
			While SampleOrganization.Next() Do
				
				If Not ValueIsFilled(SampleOrganization.Organization) Then
					ObjectTypeString.PictureIndex = 0;
					Continue;
				EndIf;
				
				OrganizationLine = ObjectTypeString.Rows.Add();
				OrganizationLine.Setting = SampleOrganization.Organization;
				OrganizationLine.Presentation = SampleOrganization.Organization;
				OrganizationLine.PictureIndex = 1;
				
				SamplePartner = SampleOrganization.Select(QueryResultIteration.ByGroups);
				
				While SamplePartner.Next() Do
					
					If Not ValueIsFilled(SamplePartner.Partner) Then
						OrganizationLine.PictureIndex = 0;
						Continue;
					EndIf;
					
					PartnerLine = OrganizationLine.Rows.Add();
					PartnerLine.Setting = SamplePartner.Partner;
					PartnerLine.Presentation = SamplePartner.Partner;
					
				EndDo;
				
			EndDo;
			
		EndDo;
	EndIf;

	ValueToFormAttribute(ValueTree, "ObjectPrintSettings");
	
EndProcedure

&AtServer
Function RemovePrintServerSetting(RowID)
	
	ObjectType  = "";
	Organization = Catalogs.Companies.EmptyRef();
	Partner     = Catalogs.Partners.EmptyRef();
	
	CurrentData = ObjectPrintSettings.FindByID(RowID);
	
	If CurrentData = Undefined Then
		Return False;
	EndIf;
	
	If TypeOf(CurrentData.Setting) = Type("String") Then
		If Not UserRightsCached.SaveObjectPrintSettingsByDefault() Then
			CommonClientServer.MessageToUser(NStr("vi = 'Không có quyền xóa bỏ tùy chỉnh in';
													|ru = 'Нет прав на удаление настройки печати';
													|en = 'You are not authorized to delete the print setting'; fa = 'You are not authorized to delete the print setting';
													|it = 'Diritti insufficienti per eliminare le impostazioni di stampa';
													|pl = 'Brak uprawnień do usunięcia ustawień drukowania';
													|tr = 'Yazdırma ayarlarının silinmesi için erişim yetkisi yok'"));
			Return False;
		Else
			ObjectType = CurrentData.Setting;
		EndIf;
	ElsIf TypeOf(CurrentData.Setting) = Type("CatalogRef.Companies") Then
		If Not UserRightsCached.SaveObjectPrintSettingsByDefault() Then
			CommonClientServer.MessageToUser(NStr("vi = 'Không có quyền xóa bỏ tùy chỉnh mẫu in theo doanh nghiệp';
													|ru = 'Нет прав на удаление настройки печати по организации';
													|en = 'No rights to delete company print setting'; fa = 'No rights to delete company print setting';
													|it = 'Diritti insufficienti per eliminare le impostazioni di stampa relative all''azienda';
													|pl = 'Brak uprawnień do usunięcia ustawień drukowania wg firmy';
													|tr = 'İş yeri için yazdırma ayarlarının silinmesine ilişkin erişim yetkisi yok'"));
			Return False;
		Else
			ObjectType  = CurrentData.GetParent().Setting;
			Organization = CurrentData.Setting;
		EndIf;
	ElsIf TypeOf(CurrentData.Setting) = Type("CatalogRef.Partners") Then
		If Not UserRightsCached.AddEditObjectPrintSettings() Then
			CommonClientServer.MessageToUser(NStr("vi = 'Không có quyền xóa tùy chỉnh mẫu in theo bạn hàng';
													|ru = 'Нет прав на удаление настройки печати по партнеру';
													|en = 'No rights to delete partner print setting'; fa = 'No rights to delete partner print setting';
													|it = 'Diritti insufficienti per eliminare le impostazioni di stampa relative al partner';
													|pl = 'Brak uprawnień do usunięcia ustawień drukowania wg partnera';
													|tr = 'İş ortağı için yazdırma ayarlarının silinmesine ilişkin erişim yetkisi yok'"));
			Return False;
		Else
			ObjectType  = CurrentData.GetParent().GetParent().Setting;
			Organization = CurrentData.GetParent().Setting;
			Partner     = CurrentData.Setting;
		EndIf;
	EndIf;
	
	RecordKeyData = New Structure();
	RecordKeyData.Insert("ObjectType",  ObjectType);
	RecordKeyData.Insert("Organization", Organization);
	RecordKeyData.Insert("Partner",     Partner);
	
	If RecordExists(RecordKeyData) Then
		
		ArrayOfConstructorParameters = New Array();
		ArrayOfConstructorParameters.Add(RecordKeyData);
		InformationRegisters.ObjectPrintSettings.DeleteObjectPrintingSettings(ObjectType, Organization, Partner);
		FillInObjectPrintingSettings();
		
		Return True;
		
	Else
		
		Return False;
		
	EndIf;
	
EndFunction

&AtServer
Function RecordExists(RecordKeyData)
	
	Query = New Query("SELECT
	|	EmailAccountSettings.ObjectType
	|FROM
	|	InformationRegister.ObjectPrintSettings AS EmailAccountSettings
	|WHERE
	|	EmailAccountSettings.ObjectType = &ObjectType
	|	AND EmailAccountSettings.Organization = &Organization
	|	AND EmailAccountSettings.Partner = &Partner
	|");
	
	Query.SetParameter("ObjectType",  RecordKeyData.ObjectType);
	Query.SetParameter("Organization", RecordKeyData.Organization);
	Query.SetParameter("Partner",     RecordKeyData.Partner);
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

#EndRegion
