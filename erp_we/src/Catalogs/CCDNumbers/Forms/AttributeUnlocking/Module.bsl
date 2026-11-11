
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Refund upon receipt of the form for analysis.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	FormAttributes		= GetAttributes();
	CCDNumberTypeOfObject	= ?(ValueIsFilled(Parameters.CCDNumberType),
							Parameters.CCDNumberType,
							Enums.CCDNumberTypes.CCDNumber);
	KeepRecordsOfRNPT		= Parameters.KeepRecordsOfRNPT;
	
	NamesOfTraceabilityAttributes = NamesOfTraceabilityAttributes(ThisObject);
	
	For Each Attribute In FormAttributes Do
		If Items.Find(Attribute.Name) = Undefined Then
			Continue;
		EndIf;
		
		PropsUsed = True;
		
		If Attribute.Name = Items.Code.Name
			And (CCDNumberTypeOfObject = Enums.CCDNumberTypes.ProductBatchIDNumber
				Or CCDNumberTypeOfObject = Enums.CCDNumberTypes.KitRNPT) Then
			
			Items[Attribute.Name].Title = NStr("vi = 'Cho phép chỉnh sửa số đăng ký lô hàng';
												|ru = 'Разрешить редактирование номера РНПТ';
												|en = 'Allow editing RNPT'; fa = 'Allow editing RNPT';
												|it = 'Consentire le modifiche del numero di registrazione lotti';
												|pl = 'Zezwól na edycję numeru rejestracyjnego partii towaru';
												|tr = 'RNTP Numarasının düzenlenmesine izin ver'");
			
		ElsIf KeepRecordsOfRNPT
			And Attribute.Name = Items.AmountByProductBatchID.Name
			And CCDNumberTypeOfObject = Enums.CCDNumberTypes.KitRNPT Then
			
			Items[Attribute.Name].Title = NStr("vi = 'Cho phép soạn giá trị bộ';
												|ru = 'Разрешить редактирование стоимости комплекта';
												|en = 'Allow editing kit cost'; fa = 'Allow editing kit cost';
												|it = 'Разрешить редактирование стоимости комплекта';
												|pl = 'Allow editing kit cost';
												|tr = 'Set maliyetinin düzenlenmesine izin ver'");
			
		ElsIf Not KeepRecordsOfRNPT
			And NamesOfTraceabilityAttributes.Find(Attribute.Name) <> Undefined Then
			
			PropsUsed = False;
			
		EndIf;
		
		ThisObject[Attribute.Name]			= PropsUsed;
		Items[Attribute.Name].Visible	= PropsUsed;
		
		FormAttributesNames.Add(Attribute.Name);
	EndDo;
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EnableEdit(Command)
	
	// For all enabled checkboxes, we will create an array of corresponding Catalog Attributes.
	Result = New Array;
	
	For Each Attribute In FormAttributesNames Do
		If ThisObject[Attribute.Value] Then
			Result.Add(Attribute.Value);
		EndIf;
	EndDo;
	
	Close(Result);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Function NamesOfTraceabilityAttributes(Form)
	
	Items = Form.Items;
	
	AttributesNames = New Array;
	AttributesNames.Add(Items.CCDNumberType.Name);
	AttributesNames.Add(Items.Products.Name);
	AttributesNames.Add(Items.ProductName.Name);
	AttributesNames.Add(Items.UnitOfMeasure.Name);
	AttributesNames.Add(Items.AmountByProductBatchID.Name);
	AttributesNames.Add(Items.TraceableComponents.Name);
	
	Return AttributesNames;
	
EndFunction

#EndRegion