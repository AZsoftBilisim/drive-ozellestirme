//////////////////////////////////////////////////////////////////////
// The "Internal Processing Client" module contains procedures and functions for 
// working with the internal processing mechanism.
//
//////////////////////////////////////////////////////////////////////

#Region Public

#Region FillType

// Fills in the service Attribute "The owner of the department is available" in the line according to the specified assignment
//
// Parameters:
//  CurrentData		 - Structure - data of the processed string.
//  StructureOfActions	 - Structure - describes actions, where the Key is the name of the action,
//  														   The value - Structure - activity settings.
//  CachedValues - Structure - saved values of parameters used during processing.
//
Procedure FillInProductOwnerIsAvailable(CurrentData, StructureOfActions, CachedValues) Export
	
	FINISHEDProductOwnerIsAvailable = True;
	
	If ValueIsFilled(CurrentData.Purpose) Then
		
		PropertiesPurpose = CachedValues.AssignmentProperties.Get(CurrentData.Purpose);
		
		If PropertiesPurpose = Undefined Then 
		
			ExceptionText = 
				NStr("vi = 'Thử điền mục tin hệ thống theo dữ liệu của mục đích chỉ định trên Client.';
					|ru = 'Попытка заполнение служебного реквизита по данным указанного назначения на клиенте.';
					|en = 'Try to fill in internal attribute according to the data of the specified assignment on the client.'; fa = 'Try to fill in internal attribute according to the data of the specified assignment on the client.';
					|it = 'Попытка заполнение служебного реквизита по данным указанного назначения на клиенте.';
					|pl = 'Try to fill in internal attribute according to the data of the specified assignment on the client.';
					|tr = 'İstemcide belirtilen atamaların verilere göre hizmet özniteliğini doldurma girişimi.'");
					
			Raise ExceptionText;
			
		Else
			FINISHEDProductOwnerIsAvailable =
				Not PropertiesPurpose.ThisIsAppointmentOfGiver2_5
				And True;
		EndIf;
		
	EndIf;
	
	CurrentData.FINISHEDProductOwnerIsAvailable = FINISHEDProductOwnerIsAvailable;
	
	If Not CurrentData.FINISHEDProductOwnerIsAvailable Then
		CurrentData.ProductOwner = Undefined;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion