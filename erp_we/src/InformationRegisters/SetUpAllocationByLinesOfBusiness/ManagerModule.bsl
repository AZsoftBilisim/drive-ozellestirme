#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export
	Handler = Handlers.Add();
	Handler.Procedure = "InformationRegisters.SetUpAllocationByLinesOfBusiness.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.27.19";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("33ed1c42-17e8-4104-8b0c-a93b76737381");
	Handler.Multithreaded = True;
	Handler.Order = Enums.OrderOfUpdateHandlers.Noncritical;
	Handler.UpdateDataFillingProcedure = "InformationRegisters.SetUpAllocationByLinesOfBusiness.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Comment = NStr("ru = 'Заменяет в регистре сведений ""Настройка распределения по направлениям деятельности"" 
										| пустые ссылки на справочники ""Номенклатура"" и ""Партнеры"" на Неопределено.';
										|vi = 'Replaces empty references to the ""Items"" and ""Partners"" catalogs
										|in the ""Settings of allocation by lines of business"" information register with Undefined.';
										|en = 'Replaces empty references to the ""Items"" and ""Partners"" catalogs
										|in the ""Settings of allocation by lines of business"" information register with Undefined.'; fa = 'Replaces empty references to the ""Items"" and ""Partners"" catalogs
										|in the ""Settings of allocation by lines of business"" information register with Undefined.';
										|it = 'Replaces empty references to the ""Items"" and ""Partners"" catalogs
										|in the ""Settings of allocation by lines of business"" information register with Undefined.';
										|pl = 'Replaces empty references to the ""Items"" and ""Partners"" catalogs
										|in the ""Settings of allocation by lines of business"" information register with Undefined.';
										|tr = '""Faaliyet alanlarına göre dağıtım ayarı"" bilgi kaydında 
										|, ""Stok kalemi"" ve ""Partnerler"" kılavuzlarına ait boş bağlantıları ""Belirsiz"" ile değiştirir.'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.InformationRegisters.SetUpAllocationByLinesOfBusiness.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.InformationRegisters.SetUpAllocationByLinesOfBusiness.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.InformationRegisters.SetUpAllocationByLinesOfBusiness.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");
	
EndProcedure
	
// Registers documents for processing for modification.
//
// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullRegistersNames = "InformationRegister.SetUpAllocationByLinesOfBusiness";
	SelectionParameters.SelectionMethod = InfobaseUpdate.SelectionMethodOfIndependentInfoRegistryMeasurements();
	
	AdditionalParameters = InfobaseUpdate.AdditionalProcessingMarkParameters();
	AdditionalParameters.Insert("IsIndependentInformationRegister", True);
	AdditionalParameters.Insert("FullRegisterName", "InformationRegister.SetUpAllocationByLinesOfBusiness");
	
	Query = New Query();
	Query.Text =
	"SELECT
	|	SetUpAllocationByLinesOfBusiness.Period AS Period,
	|	SetUpAllocationByLinesOfBusiness.Organization AS Organization,
	|	SetUpAllocationByLinesOfBusiness.Products AS Products,
	|	SetUpAllocationByLinesOfBusiness.Department AS Department,
	|	SetUpAllocationByLinesOfBusiness.Partner AS Partner,
	|	SetUpAllocationByLinesOfBusiness.Warehouse AS Warehouse
	|FROM
	|	InformationRegister.SetUpAllocationByLinesOfBusiness AS SetUpAllocationByLinesOfBusiness
	|WHERE
	|	(SetUpAllocationByLinesOfBusiness.Products = VALUE(Catalog.Products.EmptyRef)
	|			OR SetUpAllocationByLinesOfBusiness.Partner = VALUE(Catalog.Partners.EmptyRef))";
	
	RecordedMeasurements = Query.Execute().Unload();
	InfobaseUpdate.MarkForProcessing(Parameters, RecordedMeasurements, AdditionalParameters);
	
EndProcedure

// An update handler.
// 
// Parameters:
//  Parameters - See InfobaseUpdate.MainProcessingMarkParameters.
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	FullRegisterName = "InformationRegister.SetUpAllocationByLinesOfBusiness";
	
	If Not InfobaseUpdate.HasDataToProcess(Parameters.Queue, FullRegisterName) Then
		Parameters.ProcessingCompleted = True;
		Return;
	EndIf;
	
	TableUpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	For Each String In TableUpdatedData Do
		
		Set = Undefined;
		
		BeginTransaction();
		Try
			
			Block = New DataLock();
			
			LockItem = Block.Add("InformationRegister.SetUpAllocationByLinesOfBusiness");
			LockItem.SetValue("Period",			String.Period);
			LockItem.SetValue("Organization",		String.Organization);
			LockItem.SetValue("Products",	String.Products);
			LockItem.SetValue("Department",	String.Department);
			LockItem.SetValue("Partner",			String.Partner);
			LockItem.SetValue("Warehouse",			String.Warehouse);
			
			Block.Lock();
			
			Set = InformationRegisters.SetUpAllocationByLinesOfBusiness.CreateRecordSet();
			Set.Filter.Period.Set(String.Period);
			Set.Filter.Organization.Set(String.Organization);
			If ValueIsFilled(String.Products) Then
				Set.Filter.Products.Set(String.Products);
			EndIf;
			Set.Filter.Department.Set(String.Department);
			If ValueIsFilled(String.Partner) Then
				Set.Filter.Partner.Set(String.Partner);
			EndIf;
			Set.Filter.Warehouse.Set(String.Warehouse);
			Set.Read();
			
			For Each Record In Set Do
				If Record.Products = Catalogs.Products.EmptyRef() Then
					Record.Products = Undefined;
				EndIf;
				If Record.Partner = Catalogs.Partners.EmptyRef() Then
					Record.Partner = Undefined;
				EndIf;
			EndDo;
			
			InfobaseUpdate.WriteRecordSet(Set);
			CommitTransaction();
			
		Except
			RollbackTransaction();
			If Set = Undefined Then
				Set = InformationRegisters.SetUpAllocationByLinesOfBusiness.CreateRecordSet();
				Set.Filter.Period.Set(String.Period);
				Set.Filter.Organization.Set(String.Organization);
				Set.Filter.Products.Set(String.Products);
				Set.Filter.Department.Set(String.Department);
				Set.Filter.Partner.Set(String.Partner);
				Set.Filter.Warehouse.Set(String.Warehouse);
			EndIf;
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), Set);
		EndTry;
		
	EndDo;
	AdditionalParameters = InfobaseUpdate.AdditionalProcessingMarkParameters();
	AdditionalParameters.IsIndependentInformationRegister = True;
	AdditionalParameters.FullRegisterName = FullRegisterName;

	InfobaseUpdate.MarkProcessingCompletion(TableUpdatedData, AdditionalParameters);
	Parameters.ProcessingCompleted = Not InfobaseUpdate.HasDataToProcess(Parameters.Queue, FullRegisterName);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
