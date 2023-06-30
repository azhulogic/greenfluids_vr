function [ ] = create_obj()
    close all
    clc
    %% Data Import and Read

    for NumberDataFiles = 1 : 24
        tic
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %--                                                             --%
        %-- NOTE:                                                       --%
        %--                                                             --%
        %-- YOU MAY HAVE TO CREATE THE 'FullSetOBJ' DIRECTORY YOURSELF  --%
        %-- AND PLACE IT IN THE DESIRED DIRECTORY ('FileDir')           --%
        %--                                                             --%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %Customize in between ''
        FileDir = '';
        
        ExportFolder='PracticeOBJ';

        [SUCCESS,MESSAGE,~] = mkdir(fullfile(FileDir,ExportFolder));
        
         if(~isempty(MESSAGE)) && (SUCCESS)
             fprintf(1, '%s \nPress ENTER to continue or Ctrl+C to exit and rename directory in code.\n', MESSAGE);
             pause
         else
             error(MESSAGE);
         end %if
        
         %Customize in between ''
        GridDir = fullfile(FileDir, '');
        
        %Customize in between ''
        FileName = ['', sprintf('%02d',NumberDataFiles),'.dat'];
        
        DataFile = fullfile(FileDir, FileName);
        
        fprintf(1, '\n*******************************************************************\n');
        fprintf(1,   '*--                                                             --*\n');
        fprintf(1,   '*--         Data for Trapezoid_All_Interp_Plot3D_%02d:            --*\n', NumberDataFiles);
        fprintf(1,   '*--                                                             --*\n');
        fprintf(1,   '*******************************************************************\n');
        % read in from plot3d

        fprintf(1, 'Reading in plot3d files...\n');
        fid = fopen(GridDir);
        ints = fread(fid,4,'int32',0);
        fprintf(1, '--- completed ints = fread()...\n');

        ox = ints(2);
        oy = ints(3);
        oz = ints(4);

        datain = fread(fid,(4*ox*oy*oz)+2,'single', 0);
        fclose(fid);
        fprintf(1, '--- completed datain = fread()...\n');
        
        x = zeros(1,ox);
        y = zeros(1,length(16:oy-15));
        z = zeros(1,oz);
        
        for k=1:1:oz
            for j=16:1:oy-15
                for i=1:1:ox
                    x(i) = datain(2+i+((j-1)*ox)+((k-1)*ox*oy));
                    y(j-15) = datain((ox*oy*oz)+2+i+((j-1)*ox)+((k-1)*ox*oy));
                    z(k) = datain((2*ox*oy*oz)+2+i+((j-1)*ox)+((k-1)*ox*oy));
                end %for i
            end %for j
        end %for k
        
        fprintf(1, '--- completed for loops...\n');
        clear datain

        [X_grid,Y_grid,Z_grid] = meshgrid(y,x,z);
        fprintf(1, '--- completed meshgrid...\n');

        fid = fopen(DataFile);
        ints3 = fread(fid,5,'int32',0);

        datain = fread(fid,(ints3(5)*ox*oy*oz)+2,'single',0);
        fprintf(1, '--- completed fread()...\n');
        fclose(fid);

        u = zeros(ox, length(16:oy-15), oz);
        v = zeros(ox, length(16:oy-15), oz);
        w = zeros(ox, length(16:oy-15), oz);
        
        for k=1:1:oz
            for j=16:1:oy-15
                for i=1:1:ox
                    u(i,j-15,k) = datain(               2 + i+((j-1)*ox)+((k-1)*ox*oy));
                    v(i,j-15,k) = datain((ox*oy*oz*1) + 2 + i+((j-1)*ox)+((k-1)*ox*oy));
                    w(i,j-15,k) = datain((ox*oy*oz*2) + 2 + i+((j-1)*ox)+((k-1)*ox*oy));
                end %for i
            end %for j
        end %for k
        fprintf(1, '--- completed for loops... ');

        clear datain
        toc
        %% Computations
        fprintf(1, 'Computing gradients...\n');
        [dudx, dudy, dudz, dvdx, dvdy, dvdz, dwdx, dwdy, dwdz, q] = GradientCalcs( x, y, z, u, v, w); %#ok<ASGLU>
        
        fprintf(1, 'Computing omega_z...\n');
        omegaZ = dvdx - dudy;

        fprintf(1, 'Normalizing velocities...\n');
        % normalize
        u = u ./ 0.05946;
        v = v ./ 0.05946;
        w = w ./ 0.05946;

        q1p = max(max(max(q)))/100;                 % 1% of max q
        
        %% Creating the Pitching Panel in 3D
        fprintf(1, 'Creating the pitching panel in 3D...\n');

        FinShape = PanelGeneration(NumberDataFiles, FileDir);

        %% Fin Grid

        fprintf(1, 'Creating fin grid...\n');
        Width_max  = 0.1200;
        Width_min  =-0.1200;
        Height_max = 0.1280;
        Height_min =-0.1280;
        Length_max = 0.0000;
        Length_min =-0.1010;

        % grid axis arrays
        Width_array  =-0.0008 + Width_min  : 0.0001 : 0.0008 + Width_max;   % y-axis
        Length_array =-0.0100 + Length_min : 0.0005 : 0.0100 + Length_max;  % x-axis
        Height_array =    Height_min       : 0.0010 :    Height_max;        % z-axis

        % sizes of each array
        CountY = length(Width_array);
        CountX = length(Length_array);
        CountZ = length(Height_array);
        %             TotalCount=CountX*CountY*CountZ;

        % formatting the arrays
        Length_array = transpose(Length_array);
        %             Width_array=Width_array;

        Z_repeat=CountX*CountY;
        for a = 1 : length(Height_array)
            Z_fin_set = repmat(Height_array(a),Z_repeat,1);
            Z_fin_points(1+(a-1)*Z_repeat:a*Z_repeat)=Z_fin_set;
        end %for a
        Height = Z_fin_points;

        Height_grid = reshape(Height,CountY,CountX,CountZ);

        % creating the grid for the panel
        [finX,finY,finZ] = meshgrid(Width_array,Length_array,Height_grid(1,1,:));  % Grid


        %% Creating the Z-Vorticity Isosurface and Calculating the Isonormals  

        fprintf(1, 'Creating z-vorticity isosurface and isonormals...\n');
        % Face and vertex data generated
        fv_Omega_Z = isosurface(X_grid,Y_grid,Z_grid,q,q1p,omegaZ);    %Isovalue is Input 4
        % Spacing the color array  
        caxis([-5,5]);

        % Calculates the isonormals
        figure(4*NumberDataFiles-3)
        patch_Omega_Z       = patch(isosurface(X_grid,Y_grid,Z_grid,q,q1p));    % Creates a 'patch' of the omega_z isosurface
        VertexNorms_Omega_Z = isonormals(X_grid,Y_grid,Z_grid,q,patch_Omega_Z); %calculates the normal vectors from the vertices

        % Normalizing the Isonormal Vectors for Z-Vorticity
        L_Omega_Z= sqrt(VertexNorms_Omega_Z(:,1).^2+VertexNorms_Omega_Z(:,2).^2+VertexNorms_Omega_Z(:,3).^2); % Resultant magnitude of each normal vector
        VertexNorms_Omega_Z(:,1) = VertexNorms_Omega_Z(:,1)./L_Omega_Z;
        VertexNorms_Omega_Z(:,2) = VertexNorms_Omega_Z(:,2)./L_Omega_Z;
        VertexNorms_Omega_Z(:,3) = VertexNorms_Omega_Z(:,3)./L_Omega_Z;

        % Creating the Isosurface figure for Z-Vorticity
        close(figure(4*NumberDataFiles-3))
        figure(4*NumberDataFiles-3)
        isosurface(X_grid,Y_grid,Z_grid,q,q1p,omegaZ);
        caxis([-10,10]);
        colormap(jet)
        %             t=title(strcat('Isosurface of Z-Vorticity from Pitching Panel ',sprintf(num2str(NumberDataFiles),' %s'))); %Title is Input 5
        title(strcat('Isosurface of Z-Vorticity from Pitching Panel ',sprintf(num2str(NumberDataFiles),' %s'))); %Title is Input 5
        xlabel('Width of Flow')
        ylabel('Length of Flow')
        zlabel('Height of Flow')
        grid on
        axis equal
        colorbar
        pause(2.0)

        figure(4*NumberDataFiles-3); 
        hold on; 
        plot(FinShape,'FaceColor',[0 0 0.3]);   %Plotting Fin on Z-Vorticity
        pause(2.0)

        %% Creating the X-Velocity Isosurface and Calculating Isonormals
        fprintf(1, 'Creating x-velocity isosurface and isonormals...\n');
        %face and vertex data generated
        figure(2*(NumberDataFiles+(NumberDataFiles-1)))
        fv_U_Surplus= isosurface(X_grid(7:110,:,:),Y_grid(7:110,:,:),Z_grid(7:110,:,:),u(7:110,:,:),1.1);    % Flow at 10% above freestream velocity
        fv_U_Deficit= isosurface(X_grid(7:110,:,:),Y_grid(7:110,:,:),Z_grid(7:110,:,:),u(7:110,:,:),0.9);    % Flow at 10% below the freestream velocity

        % Calculate the isonormals
        patch_U_Surplus=patch(isosurface(X_grid(7:110,:,:),Y_grid(7:110,:,:),Z_grid(7:110,:,:),u(7:110,:,:),1.1));  % Creates a patch of the U_Velocity Isosurface at surplus momentum
        patch_U_Deficit=patch(isosurface(X_grid(7:110,:,:),Y_grid(7:110,:,:),Z_grid(7:110,:,:),u(7:110,:,:),0.9));  % Creates a patch of the U_Velocity Isosurface at deficit momentum

        VertexNorms_U_Surplus= isonormals(X_grid(7:110,:,:),Y_grid(7:110,:,:),Z_grid(7:110,:,:),u(7:110,:,:),patch_U_Surplus); % Calculates the normal vectors of the vertices
        VertexNorms_U_Deficit= isonormals(X_grid(7:110,:,:),Y_grid(7:110,:,:),Z_grid(7:110,:,:),u(7:110,:,:),patch_U_Deficit); % Calculates the normal vectors of the vertices

        %Normalizing the Isonormal Vectors for x-Velocity (surplus momentum)
        L_U_Surplus= sqrt(VertexNorms_U_Surplus(:,1).^2+VertexNorms_U_Surplus(:,2).^2+VertexNorms_U_Surplus(:,3).^2); % Resultant magnitude of each normal vector
        VertexNorms_U_Surplus(:,1)=VertexNorms_U_Surplus(:,1)./L_U_Surplus;
        VertexNorms_U_Surplus(:,2)=VertexNorms_U_Surplus(:,2)./L_U_Surplus;
        VertexNorms_U_Surplus(:,3)=VertexNorms_U_Surplus(:,3)./L_U_Surplus;

        %Normalizing the Isonormal Vectors for x-Velocity (deficit momentum)
        L_U_Deficit= sqrt(VertexNorms_U_Deficit(:,1).^2+VertexNorms_U_Deficit(:,2).^2+VertexNorms_U_Deficit(:,3).^2); % Resultant magnitude of each normal vector
        VertexNorms_U_Deficit(:,1)=VertexNorms_U_Deficit(:,1)./L_U_Deficit;
        VertexNorms_U_Deficit(:,2)=VertexNorms_U_Deficit(:,2)./L_U_Deficit;
        VertexNorms_U_Deficit(:,3)=VertexNorms_U_Deficit(:,3)./L_U_Deficit;

        % Creating the Isosurface figure for x-Velocity
        close(figure(2*(NumberDataFiles+(NumberDataFiles-1))))
        pause(2.0)
        figure(2*(NumberDataFiles+(NumberDataFiles-1)))
        isosurface(X_grid(7:110,:,:),Y_grid(7:110,:,:),Z_grid(7:110,:,:),u(7:110,:,:),1.1)
        patch_U_Surplus=patch(isosurface(X_grid(7:110,:,:),Y_grid(7:110,:,:),Z_grid(7:110,:,:),u(7:110,:,:),1.1));
        set(patch_U_Surplus,'FaceColor',[0 0 1],'EdgeColor','none');    
        %             t=title(strcat('Isosurface of X-Velocity from Pitching Panel ', sprintf(num2str(NumberDataFiles),' %s')));   %Title is Input 7
        title(strcat('Isosurface of X-Velocity from Pitching Panel ', sprintf(num2str(NumberDataFiles),' %s')));   %Title is Input 7
        xlabel('Width of Flow')
        ylabel('Length of Flow')
        zlabel('Height of Flow')
        grid on
        figure(2*(NumberDataFiles+(NumberDataFiles-1)));
        hold on; 
        plot(FinShape,'FaceColor',[0 0 0.3]);
        pause(2.0)
        figure(2*(NumberDataFiles+(NumberDataFiles-1))); 
        hold on;
        isosurface(X_grid(7:110,:,:),Y_grid(7:110,:,:),Z_grid(7:110,:,:),u(7:110,:,:),0.9)
        patch_U_Deficit=patch(isosurface(X_grid(7:110,:,:),Y_grid(7:110,:,:),Z_grid(7:110,:,:),u(7:110,:,:),0.9));
        set(patch_U_Deficit,'FaceColor',[1 0.4 0],'EdgeColor','none');
        pause(2.0)

        % NOTE: Blue represents above freestream velocity and orange represents
        %       below the freestream velocity

         %% Creating the Y-Velocity Isosurface and Calculating Isonormals
        fprintf(1, 'Creating y-velocity isosurface and isonormals...\n');
        % face and vertex data generated
        figure(3+4*(NumberDataFiles-1))
        fv_V_Positive= isosurface(X_grid(5:end,:,:),Y_grid(5:end,:,:),Z_grid(5:end,:,:),v(5:end,:,:),0.1);     %Isovalue is Input 8
        fv_V_Negative= isosurface(X_grid(5:end,:,:),Y_grid(5:end,:,:),Z_grid(5:end,:,:),v(5:end,:,:),-0.1);

        % Calculate the isonormals
        patch_V_Positive=patch(isosurface(X_grid(5:end,:,:),Y_grid(5:end,:,:),Z_grid(5:end,:,:),v(5:end,:,:),0.1));  % Creates a patch of the V_Velocity Isosurface(+)
        patch_V_Negative=patch(isosurface(X_grid(5:end,:,:),Y_grid(5:end,:,:),Z_grid(5:end,:,:),v(5:end,:,:),-0.1));  % creates a patch of the V_Velocity Isosurface(-)

        VertexNorms_V_Positive= isonormals(X_grid(5:end,:,:),Y_grid(5:end,:,:),Z_grid(5:end,:,:),v(5:end,:,:),patch_V_Positive); % Calculates the normal vectors of the vertices (+)
        VertexNorms_V_Negative= isonormals(X_grid(5:end,:,:),Y_grid(5:end,:,:),Z_grid(5:end,:,:),v(5:end,:,:),patch_V_Negative); % Calculates the normal vecotrs of the vertices (-)


        % Normalizing the Isonormal Vectors for y-Velocity (+)
        L_V_Pos= sqrt(VertexNorms_V_Positive(:,1).^2+VertexNorms_V_Positive(:,2).^2+VertexNorms_V_Positive(:,3).^2); % Resultant magnitude of each normal vector
        VertexNorms_V_Positive(:,1)=VertexNorms_V_Positive(:,1)./L_V_Pos;
        VertexNorms_V_Positive(:,2)=VertexNorms_V_Positive(:,2)./L_V_Pos;
        VertexNorms_V_Positive(:,3)=VertexNorms_V_Positive(:,3)./L_V_Pos;

        % Normalizing the Isonormal Vectors for y-Velocity (-)
        L_V_Neg= sqrt(VertexNorms_V_Negative(:,1).^2+VertexNorms_V_Negative(:,2).^2+VertexNorms_V_Negative(:,3).^2); % Resultant magnitude of each normal vector
        VertexNorms_V_Negative(:,1)=VertexNorms_V_Negative(:,1)./L_V_Neg;
        VertexNorms_V_Negative(:,2)=VertexNorms_V_Negative(:,2)./L_V_Neg;
        VertexNorms_V_Negative(:,3)=VertexNorms_V_Negative(:,3)./L_V_Neg;


        % Creating the Isosurface figure for y-Velocity
        close(figure(3+4*(NumberDataFiles-1)))
        pause(2.0)
        figure(3+4*(NumberDataFiles-1))
        isosurface(X_grid(5:end,:,:),Y_grid(5:end,:,:),Z_grid(5:end,:,:),v(5:end,:,:),0.1)
        patch_V_Positive=patch(isosurface(X_grid(5:end,:,:),Y_grid(5:end,:,:),Z_grid(5:end,:,:),v(5:end,:,:),0.1));
        set(patch_V_Positive,'FaceColor',[0 1 0],'EdgeColor','none');
        %             t=title(strcat('Isosurface of Y-Velocity from Pitching Panel ', sprintf(num2str(NumberDataFiles),' %s')));     %Title is Input 9
        title(strcat('Isosurface of Y-Velocity from Pitching Panel ', sprintf(num2str(NumberDataFiles),' %s')));     %Title is Input 9
        xlabel('Width of Flow')
        ylabel('Length of Flow')
        zlabel('Height of Flow')
        grid on
        figure(3+4*(NumberDataFiles-1)); 
        hold on; 
        plot(FinShape,'FaceColor',[0 0 0.3]);
        pause(2.0)
        figure(3+4*(NumberDataFiles-1)); 
        hold on; 
        isosurface(X_grid(5:end,:,:),Y_grid(5:end,:,:),Z_grid(5:end,:,:),v(5:end,:,:),-0.1)
        patch_V_Negative=patch(isosurface(X_grid(5:end,:,:),Y_grid(5:end,:,:),Z_grid(5:end,:,:),v(5:end,:,:),-0.1));
        set(patch_V_Negative,'FaceColor',[1 0 0],'EdgeColor','none');
        pause(2.0)

        % NOTE: Green represents positive flow in the Y direction and Red is
        %       negative velocity in the Y direction


        %% Creating the Z-Velocity Isosurface and Calculating Isonormals
        fprintf(1, 'Creating z-velocity isosurface and isonormals...\n');
        %face and vertex data generated
        figure(4*NumberDataFiles)
        fv_W_Positive= isosurface(X_grid(6:end,:,:),Y_grid(6:end,:,:),Z_grid(6:end,:,:),w(6:end,:,:),0.1);     %Isovalue is Input 8
        fv_W_Negative= isosurface(X_grid(6:end,:,:),Y_grid(6:end,:,:),Z_grid(6:end,:,:),w(6:end,:,:),-0.1);

        % Calculate the isonormals
        patch_W_Positive=patch(isosurface(X_grid(6:end,:,:),Y_grid(6:end,:,:),Z_grid(6:end,:,:),w(6:end,:,:),0.1));  % Creates a patch of the W_Velocity Isosurface(+)
        patch_W_Negative=patch(isosurface(X_grid(6:end,:,:),Y_grid(6:end,:,:),Z_grid(6:end,:,:),w(6:end,:,:),-0.1));  % creates a patch of the W_Velocity Isosurface(-)

        VertexNorms_W_Positive= isonormals(X_grid(6:end,:,:),Y_grid(6:end,:,:),Z_grid(6:end,:,:),w(6:end,:,:),patch_W_Positive); % Calculates the normal vectors of the vertices (+)
        VertexNorms_W_Negative= isonormals(X_grid(6:end,:,:),Y_grid(6:end,:,:),Z_grid(6:end,:,:),w(6:end,:,:),patch_W_Negative); % Calculates the normal vecotrs of the vertices (-)


        %Normalizing the Isonormal Vectors for y-Velocity (+)
        L_W_Pos= sqrt(VertexNorms_W_Positive(:,1).^2+VertexNorms_W_Positive(:,2).^2+VertexNorms_W_Positive(:,3).^2); % Resultant magnitude of each normal vector
        VertexNorms_W_Positive(:,1)=VertexNorms_W_Positive(:,1)./L_W_Pos;
        VertexNorms_W_Positive(:,2)=VertexNorms_W_Positive(:,2)./L_W_Pos;
        VertexNorms_W_Positive(:,3)=VertexNorms_W_Positive(:,3)./L_W_Pos;

        %Normalizing the Isonormal Vectors for y-Velocity (-)
        L_W_Neg= sqrt(VertexNorms_W_Negative(:,1).^2+VertexNorms_W_Negative(:,2).^2+VertexNorms_W_Negative(:,3).^2); % Resultant magnitude of each normal vector
        VertexNorms_W_Negative(:,1)=VertexNorms_W_Negative(:,1)./L_W_Neg;
        VertexNorms_W_Negative(:,2)=VertexNorms_W_Negative(:,2)./L_W_Neg;
        VertexNorms_W_Negative(:,3)=VertexNorms_W_Negative(:,3)./L_W_Neg;


        % Creating the Isosurface figure for y-Velocity
        close(figure(4*NumberDataFiles))
        pause(2.0)
        figure(4*NumberDataFiles)
        isosurface(X_grid(6:end,:,:),Y_grid(6:end,:,:),Z_grid(6:end,:,:),w(6:end,:,:),0.1)
        patch_W_Positive=patch(isosurface(X_grid(6:end,:,:),Y_grid(6:end,:,:),Z_grid(6:end,:,:),w(6:end,:,:),0.1));
        set(patch_W_Positive,'FaceColor',[0.8 0 0.8],'EdgeColor','none');
        %             t=title(strcat('Isosurface of Z-Velocity from Pitching Panel', sprintf(num2str(NumberDataFiles),' %s')));     %Title is Input 9
        title(strcat('Isosurface of Z-Velocity from Pitching Panel', sprintf(num2str(NumberDataFiles),' %s')));     %Title is Input 9
        xlabel('Width of Flow')
        ylabel('Length of Flow')
        zlabel('Height of Flow')
        grid on
        figure(4*NumberDataFiles); 
        hold on; 
        plot(FinShape,'FaceColor',[0 0 0.3]);
        pause(2.0)
        figure(4*NumberDataFiles); 
        hold on; 
        isosurface(X_grid(6:end,:,:),Y_grid(6:end,:,:),Z_grid(6:end,:,:),w(6:end,:,:),-0.1)
        patch_W_Negative=patch(isosurface(X_grid(6:end,:,:),Y_grid(6:end,:,:),Z_grid(6:end,:,:),w(6:end,:,:),-0.1));
        set(patch_W_Negative,'FaceColor',[1 1 0.2],'EdgeColor','none');
        pause(2.0)

        % NOTE: Purple represents positive flow in the Z direction and Yellow is
        %       negative velocity in the Z direction
        
        %% Computing Pitching Panel Data to Write to the OBJ file

        fprintf(1, 'Computing pitching panel data to write to the OBJ file...\n');
        V=inShape(FinShape,finX,finY,finZ);
        [FaceIndices,Vertices]=boundaryFacets(FinShape);
        SimpleVertNorms=isonormals(finX,finY,finZ,V,Vertices);
        Panel_Vertices=Vertices;
        Panel_Faces=FaceIndices;
        Panel_Isonorms=SimpleVertNorms;

        %% Combining Flow and Panel Vertices, IsoNormal Vectors, and Faces
        % Concatenating Flow and Panel Data Verically

        % Z-Vorticity
        fprintf(1, '---> z-vorticity...\n');
        Flow_Vertices_Omega_Z=fv_Omega_Z.vertices;
        Flow_Faces_Omega_Z=fv_Omega_Z.faces;
        Flow_Isonorms_Omega_Z=VertexNorms_Omega_Z;
        CountVerts_Omega_Z=length(Flow_Vertices_Omega_Z(:,1));

        % X-Velocity
        fprintf(1, '---> x-velocity...\n');
        Flow_Vertices_U_Surplus=fv_U_Surplus.vertices;   %vertices
        Flow_Vertices_U_Deficit=fv_U_Deficit.vertices;

        Flow_Faces_U_Surplus=fv_U_Surplus.faces;         %faces
        Flow_Faces_U_Deficit=fv_U_Deficit.faces;

        Flow_Isonorms_U_Surplus=VertexNorms_U_Surplus;   %vertex normals
        Flow_Isonorms_U_Deficit=VertexNorms_U_Deficit;

        CountVerts_U_Surplus=length(Flow_Vertices_U_Surplus(:,1));   %number of vertices
        CountVerts_U_Deficit=length(Flow_Vertices_U_Deficit(:,1));   %number of vertices 

        % Y-Velocity
        fprintf(1, '---> y-velocity...\n');
        Flow_Vertices_V_Positive=fv_V_Positive.vertices;   %vertices
        Flow_Vertices_V_Negative=fv_V_Negative.vertices;

        Flow_Faces_V_Negative=fv_V_Negative.faces;        %faces
        Flow_Faces_V_Positive=fv_V_Positive.faces;

        Flow_Isonorms_V_Positive=VertexNorms_V_Positive;       %vertex normals
        Flow_Isonorms_V_Negative=VertexNorms_V_Negative;

        CountVerts_V_Positive=length(Flow_Vertices_V_Positive(:,1));  %number of vertices
        CountVerts_V_Negative=length(Flow_Vertices_V_Negative(:,1));  %number of vertices

        % Z-Velocity
        fprintf(1, '---> z-velocity...\n');
        Flow_Vertices_W_Positive=fv_W_Positive.vertices;   %vertices
        Flow_Vertices_W_Negative=fv_W_Negative.vertices;

        Flow_Faces_W_Positive=fv_W_Positive.faces;        %faces
        Flow_Faces_W_Negative=fv_W_Negative.faces;

        Flow_Isonorms_W_Positive=VertexNorms_W_Positive;     %vertex normals
        Flow_Isonorms_W_Negative=VertexNorms_W_Negative;

        CountVerts_W_Positive=length(Flow_Vertices_W_Positive(:,1));  %number of vertices
        CountVerts_W_Negative=length(Flow_Vertices_W_Negative(:,1));  %number of vertices

        % Updating Face Indices and Vertical Concatenation of Matrices
        Updt_Panel_Faces_Omega_Z=zeros(20,3);
        for q=1:60
            Updt_Panel_Faces_Omega_Z(q)=Panel_Faces(q)+CountVerts_Omega_Z;
        end

        % Updating X velocity face indices
        Updt_Panel_Faces_U=zeros(20,3);
        for r=1:60
            Updt_Panel_Faces_U(r)=Panel_Faces(r)+CountVerts_U_Surplus+CountVerts_U_Deficit;
        end

        Updt_Flow_Faces_U_Deficit=zeros(size(Flow_Faces_U_Deficit));
        for r=1:3*length(Flow_Faces_U_Deficit)
            Updt_Flow_Faces_U_Deficit(r)=Flow_Faces_U_Deficit(r)+CountVerts_U_Surplus;
        end

        % Updating Y velocity face indices
        Updt_Panel_Faces_V=zeros(20,3);
        for s=1:60
            Updt_Panel_Faces_V(s)=Panel_Faces(s)+CountVerts_V_Positive+CountVerts_V_Negative;
        end

        Updt_Flow_Faces_V_Negative=zeros(size(Flow_Faces_V_Negative));
        for s=1:3*length(Flow_Faces_V_Negative)
            Updt_Flow_Faces_V_Negative(s)=Flow_Faces_V_Negative(s)+CountVerts_V_Positive;
        end

        % Updating Z velocity face indices
        Updt_Panel_Faces_W=zeros(20,3);
        for t=1:60
            Updt_Panel_Faces_W(t)=Panel_Faces(t)+CountVerts_W_Positive+CountVerts_W_Negative;
        end

        Updt_Flow_Faces_W_Negative=zeros(size(Flow_Faces_W_Negative));
        for t=1:3*length(Flow_Faces_W_Negative)
            Updt_Flow_Faces_W_Negative(t)=Flow_Faces_W_Negative(t)+CountVerts_W_Positive;
        end

        % New Info Sets for OBJ Export
        Vertices_Omega_Z=vertcat(Flow_Vertices_Omega_Z,Panel_Vertices);     %#ok<NASGU> <-- Suppresses this error message for unused variable.
        Faces_Omega_Z=vertcat(Flow_Faces_Omega_Z,Updt_Panel_Faces_Omega_Z); %#ok<NASGU> <-- Suppresses this error message for unused variable.
        Isonorms_Omega_Z=vertcat(Flow_Isonorms_Omega_Z,Panel_Isonorms);     %#ok<NASGU> <-- Suppresses this error message for unused variable.

        Vertices_U=vertcat(Flow_Vertices_U_Surplus,Flow_Vertices_U_Deficit,Panel_Vertices);
        Faces_U=vertcat(Flow_Faces_U_Surplus, Updt_Flow_Faces_U_Deficit,Updt_Panel_Faces_U);
        Isonorms_U=vertcat(Flow_Isonorms_U_Surplus,Flow_Isonorms_U_Deficit,Panel_Isonorms);



        Vertices_V=vertcat(Flow_Vertices_V_Positive,Flow_Vertices_V_Negative,Panel_Vertices);   %#ok<NASGU> <-- Suppresses this error message for unused variable.
        Faces_V=vertcat(Flow_Faces_V_Positive,Updt_Flow_Faces_V_Negative,Updt_Panel_Faces_V);   %#ok<NASGU> <-- Suppresses this error message for unused variable.
        Isonorms_V=vertcat(Flow_Isonorms_V_Positive,Flow_Isonorms_V_Negative,Panel_Isonorms);   %#ok<NASGU> <-- Suppresses this error message for unused variable.

        Vertices_W=vertcat(Flow_Vertices_W_Positive,Flow_Vertices_W_Negative,Panel_Vertices);   %#ok<NASGU> <-- Suppresses this error message for unused variable.
        Faces_W=vertcat(Flow_Faces_W_Positive,Updt_Flow_Faces_W_Negative,Updt_Panel_Faces_W);   %#ok<NASGU> <-- Suppresses this error message for unused variable.
        Isonorms_W=vertcat(Flow_Isonorms_W_Positive,Flow_Isonorms_W_Negative,Panel_Isonorms);   %#ok<NASGU> <-- Suppresses this error message for unused variable.

            %% Creating Material Information for .MTL File (Z-Vorticity)
            clear material
            % The loop creates a material for each color, which is to associated
            % with certain face. The 'material' information is to be  read into the
            % .mtl file (the  file supplementary to the .obj)
            
            cjet = jet;
            
            for c=1:64
                
                % calls "New Material"
                % signifies a new material being described in the .MTL file, which
                % is to be followed by the color, texture map, and reflection map
                % statements. The describing material statements can be entered in
                % any order is Property Editor is being used but since MATLAB is
                % directly writing the MTL file, the following order must be kept.
                material(6*(c-1)+ 1).type='newmtl'; 
                
                % name of color "skin"
                material(6*(c-1)+ 1).data=strcat('skin', sprintf('%02d',c));  
                
                % Used to specify the ambient reflectivity of the current material.
                % This can be done using RGB 3 element vectors. A color spectral
                % curve can also be used, but this is more complex.
                material(6*(c-1)+ 2).type='Ka';
                material(6*(c-1)+ 2).data=[0 0 0]; % =[R G B]
                
                % Used to specify the diffuse reflectivity of the current material.
                % This can also take an R G B vector, spectral file, or spectral
                % curve. We use the R G B vector system because that is what the
                % function is known to be able to read and the function "jet"
                % contains a known number of R G B vectors.
                material(6*(c-1)+ 3).type='Kd';
                material(6*(c-1)+ 3).data=cjet(c,:);
                
                % Used to specify the specular reflectivity of the specified
                % material. Same concept as before for the statement trailing the
                % .MTL input (in this case Ks).
                material(6*(c-1)+ 4).type='Ks';
                material(6*(c-1)+ 4).data=[1 1 1];
               
                
                % Tf entry could be added here, but function does not have
                % capability to read it. Tf specifies the transmission filler. This
                % determines which light is allowed to pass through and not.
                
                
                % The MTL input of illum specifies the illumination of the
                % particlar material. The value associated with illumination can be
                % anything from 0 to 10 and the illumination associated with each
                % value is listed below. We are using 'Highlight On'
                % 0		Color on and Ambient off
                % 1		Color on and Ambient on
                % 2		Highlight on
                % 3		Reflection on and Ray trace on
                % 4		Transparency: Glass on; Reflection: Ray trace on
                % 5		Reflection: Fresnel on and Ray trace on
                % 6		Transparency: Refraction on; Reflection: Fresnel off and Ray trace on
                % 7		Transparency: Refraction on; Reflection: Fresnel on and Ray trace on
                % 8		Reflection on and Ray trace off
                % 9		Transparency: Glass on; Reflection: Ray trace off
                %10		Casts shadows onto invisible surfaces
                material(6*(c-1)+ 5).type='illum';
                material(6*(c-1)+ 5).data=2;
                
                %d entry could be here. The d factor specifies the dissovle for the
                %current material. This is the amount of the specified material
                %that get dissovled in the background.
               
                % Ns is the spectular exponent for the given material. It defines
                % the focus of the specular highlight. The inputted value of the
                % 'exponent' is the value of the specular exponent. A high specular
                % exponent results in a tight concentrated highlight.
                material(6*(c-1)+ 6).type='Ns';
                material(6*(c-1)+ 6).data=27;
                
                % sharpness and Ni could also be added in this loop respectively.
                %'Sharpness' defines the sharpness of the reflections from the local
                % reflections map.
                % 'Ni'refers to the optical density of a surface. This can range
                % from values of 0.001 to 10. The higher the optical density, the
                % more light will bend around that materials' surface.
                
                % The wirte_wobj function used does not have the capabilities to
                % write texture map information to an MTL file, so the only
                % pertinent information to be created is the color and illumination
                % information.
            end
            
            % For more information on MTL file details and format, visit the link
            % shown here: https://www.mathworks.com/matlabcentral/mlc-downloads/
            % ....downloads/submissions/27982/versions/5/previews/help%20file%20
            % ....format/MTL_format.html
            % (Diane Ramey, Linda Rose, and Lisa Tyerman, 1995, Wavefront Inc.)
            
            
            
            
            
            %% Material Data for Panel
            % Panel Coloring
            material(c*6+1).type='newmtl';
            material(c*6+1).data='skin65';
            material(c*6+2).type='Ka';
        	material(c*6+2).data=[0 0 0];
        	material(c*6+3).type='Kd';
        	material(c*6+3).data=[0 0 0.3];
        	material(c*6+4).type='Ks';
        	material(c*6+4).data=[1 1 1];
        	material(c*6+5).type='illum';
        	material(c*6+5).data=2;
        	material(c*6+6).type='Ns';
        	material(c*6+6).data=27;
            
            
            
            
            
        %% Creating Surface Information for .OBJ File (Z-Vorticity)
            clear OBJ
            % Vertex coordinate information to be exported
            OBJ.vertices=Vertices_Omega_Z;
            
            % Vertex normal vector 3 element arrays to be exported
            OBJ.vertices_normal=Isonorms_Omega_Z;
            
            % Parameters from external MTL file as listed above. This is the
            % material information to be exported
            OBJ.material=material;
            
            % Notice that there is no vertice texture or vertex point data, which
            % could also be useful in the write_obj function. For our case, this
            % information is unnecessary.
            
            % For loop creating object structure used in function write_obj
            % Recall that the large vector 'indices' associates a color with each
            % face, which corresponds to some value of vorticity (curl of
            % velocity). So each iteration of the loop gives an angular velocity
            % value to the face itself.
            for d=1:length(ColorIndex)
                
                % 'g' is the polygonal and free-form statement
                OBJ.objects(3*(d-1)+1).type='g';
                
                % The 'skin' is the color of the face being referenced in each loop iteration
                OBJ.objects(3*(d-1)+1).data=strcat('skin',sprintf('%02d',ColorIndex(d)));
                
                % Signifies that a material (color) is to be given to a face
                OBJ.objects(3*(d-1)+2).type='usemtl';
                
                % The 'skin' is the color of the face being referenced in each loop iteration
                OBJ.objects(3*(d-1)+2).data=strcat('skin',sprintf('%02d',ColorIndex(d)));
                
                % Signifies a face
                OBJ.objects(3*(d-1)+3).type='f';
                OBJ.objects(3*(d-1)+3).data.vertices=Faces_Omega_Z(d,:);
                OBJ.objects(3*(d-1)+3).data.normal=Faces_Omega_Z(d,:);
                
            end
            
          
            % For more information on OBJ file details and format, visit the link
            % shown here: http://paulbourke.net/dataformats/obj/
            % (Paul Bourke, March 2012, paulbourke.net)
            
            
            
            
        %% Creating Panel OBJ information
            for e=1+length(ColorIndex):length(Faces_Omega_Z(:,1))
                
                % 'g' is the polygonal and free-form statement
                OBJ.objects(3*(e-1)+1).type='g';
                
                % The 'skin' is the color of the face being referenced in each loop iteration
                OBJ.objects(3*(e-1)+1).data='skin65';
                
                % Signifies that a material (color) is to be given to a face
                OBJ.objects(3*(e-1)+2).type='usemtl';
                
                % The 'skin' is the color of the face being referenced in each loop iteration
                OBJ.objects(3*(e-1)+2).data='skin65';
                
                % Signifies a face
                OBJ.objects(3*(e-1)+3).type='f';
                OBJ.objects(3*(e-1)+3).data.vertices=Faces_Omega_Z(e,:);
                OBJ.objects(3*(e-1)+3).data.normal=Faces_Omega_Z(e,:);
            end
            
            
            %Calls write_obj function
            %Can label the files as whatever name you want and save them where you
            %want by altering the second argument of the function.
            
            % Exported file name
            ExportName=strcat('UpstreamBody_Z_Vorticity_',sprintf('%02d',NumberDataFiles),'.obj');    %Input 10
            
            % Exported file folder
            ExportFolder='PracticeOBJ';
            
            % Full export file name and loctaion
            FullFileExport=fullfile(FileDir,ExportFolder,ExportName);
            
            % Creates the .OBJ file and places it in the specified location
            write_wobj(OBJ,FullFileExport);
            sprintf(ExportName, ' has been created.\n')
            
            clear ExportName FullFileExport

         %% Creating Material Information for .MTL File (X-Velocity)
       fprintf(1, 'Creating material info for .mtl file (x-velocity)...\n');
       clear material

       % Flow Color Info
       material(1).type='newmtl';
       material(1).data='skin01';
       material(2).type='Ka';
       material(2).data=[0 0 0];
       material(3).type='Kd';
       material(3).data=[0 0 1];   % Blue is Surplus momentum (x-direction)
       material(4).type='Ks';
       material(4).data=[1 1 1];
       material(5).type='illum';
       material(5).data=2;
       material(6).type='Ns';
       material(6).data=27;

       material(7).type='newmtl';
       material(7).data='skin02';
       material(8).type='Ka';
       material(8).data=[0 0 0];
       material(9).type='Kd';
       material(9).data=[1 0.4 0];   % Orange is Deficit momentum (x-direction)
       material(10).type='Ks';
       material(10).data=[1 1 1];
       material(11).type='illum';
       material(11).data=2;
       material(12).type='Ns';
       material(12).data=27;

       % Panel Color Info
       material(13).type='newmtl';
       material(13).data='skin03';
       material(14).type='Ka';
       material(14).data=[0 0 0];
       material(15).type='Kd';
       material(15).data=[0 0 0.3];  % Panel color is dark navy
       material(16).type='Ks';
       material(16).data=[1 1 1];
       material(17).type='illum';
       material(17).data=2;
       material(18).type='Ns';
       material(18).data=27;

         %% Creating Surface Information for .OBJ File (X-Velocity)
       fprintf(1, 'Creating surface info for .obj file (x-velocity)...\n');
       clear OBJ

       OBJ.vertices = Vertices_U;
       OBJ.vertices_normal = Isonorms_U;
       OBJ.material = material;

       % Flow OBJ info
       OBJ.objects(1).type='g';
       OBJ.objects(1).data='skin01';
       OBJ.objects(2).type='usemtl';
       OBJ.objects(2).data='skin01';
       OBJ.objects(3).type='f';
       OBJ.objects(3).data.vertices=Faces_U(1:length(Flow_Faces_U_Surplus),:);
       OBJ.objects(3).data.normal=Faces_U(1:length(Flow_Faces_U_Surplus),:);

       OBJ.objects(4).type='g';
       OBJ.objects(4).data='skin02';
       OBJ.objects(5).type='usemtl';
       OBJ.objects(5).data='skin02';
       OBJ.objects(6).type='f';
       OBJ.objects(6).data.vertices=Faces_U(length(Flow_Faces_U_Surplus)+1:length(Flow_Faces_U_Surplus)+length(Flow_Faces_U_Deficit),:);
       OBJ.objects(6).data.normal=Faces_U(length(Flow_Faces_U_Surplus)+1:length(Flow_Faces_U_Surplus)+length(Flow_Faces_U_Deficit),:);

       % Panel OBJ info
       OBJ.objects(7).type='g';
       OBJ.objects(7).data='skin03';
       OBJ.objects(8).type='usemtl';
       OBJ.objects(8).data='skin03';
       OBJ.objects(9).type='f';
       OBJ.objects(9).data.vertices=Faces_U(length(Flow_Faces_U_Surplus)+length(Flow_Faces_U_Deficit)+1:end,:);
       OBJ.objects(9).data.normal=Faces_U(length(Flow_Faces_U_Surplus)+length(Flow_Faces_U_Deficit)+1:end,:);

       % Exported file name
       ExportName=strcat('NoUpstreamBody_X_Vel_',sprintf('%02d',NumberDataFiles),'.obj');    %Input 11
        
       % Full export file name and loctaion
       FullFileExport=fullfile(FileDir,ExportFolder,ExportName);

        % Creates the .OBJ file and places it in the specified location
        fprintf(1, 'Writing to a file...\n');
        write_wobj(OBJ,FullFileExport);
        sprintf(ExportName, ' has been created.\n');
        fprintf(1, '%s has been created\n', ExportName);

        clear ExportName FullFileExport


            %% Creating Material Information for .MTL File (Y-Velocity) (+ more)
            fprintf(1, 'Creating material info for .mtl file (y-velocity)...\n');
            clear material
            
            % Flow Color Info
            material(1).type='newmtl';
            material(1).data='skin1';
            material(2).type='Ka';
        	material(2).data=[0 0 0];
        	material(3).type='Kd';
        	material(3).data=[0 1 0];   % Green is positive velocity
        	material(4).type='Ks';
        	material(4).data=[1 1 1];
        	material(5).type='illum';
        	material(5).data=2;
        	material(6).type='Ns';
        	material(6).data=27;
            
            material(7).type='newmtl';
            material(7).data='skin2';
            material(8).type='Ka';
        	material(8).data=[0 0 0];
        	material(9).type='Kd';
        	material(9).data=[1 0 0];   % Red is negative velocity
        	material(10).type='Ks';
        	material(10).data=[1 1 1];
        	material(11).type='illum';
        	material(11).data=2;
        	material(12).type='Ns';
        	material(12).data=27;
            
            % Panel Color Info
            material(13).type='newmtl';
            material(13).data='skin3';
            material(14).type='Ka';
        	material(14).data=[0 0 0];
        	material(15).type='Kd';
        	material(15).data=[0 0 0.3]; % Picthing panel color is dark navy
        	material(16).type='Ks';
        	material(16).data=[1 1 1];
        	material(17).type='illum';
        	material(17).data=2;
        	material(18).type='Ns';
        	material(18).data=27;
            
            
            %% Creating Surface Information for .OBJ File (Y-Velocity)
            fprintf(1, 'Creating surface info for .obj file (y-velocity)...\n');
            clear OBJ
            
            
            OBJ.vertices = Vertices_V;
        	OBJ.vertices_normal = Isonorms_V;
        	OBJ.material = material;
            
            % Flow OBJ info
        	OBJ.objects(1).type='g';
        	OBJ.objects(1).data='skin1';
        	OBJ.objects(2).type='usemtl';
        	OBJ.objects(2).data='skin1';
        	OBJ.objects(3).type='f';
        	OBJ.objects(3).data.vertices=Faces_V(1:length(Flow_Faces_V_Positive),:);
        	OBJ.objects(3).data.normal=Faces_V(1:length(Flow_Faces_V_Positive),:);
            
            OBJ.objects(4).type='g';
        	OBJ.objects(4).data='skin2';
        	OBJ.objects(5).type='usemtl';
        	OBJ.objects(5).data='skin2';
        	OBJ.objects(6).type='f';
        	OBJ.objects(6).data.vertices=Faces_V(length(Flow_Faces_V_Positive)+1:length(Flow_Faces_V_Positive)+length(Flow_Faces_V_Negative),:);
        	OBJ.objects(6).data.normal=Faces_V(length(Flow_Faces_V_Positive)+1:length(Flow_Faces_V_Positive)+length(Flow_Faces_V_Negative),:);
            
            % Panel OBJ info
            OBJ.objects(7).type='g';
        	OBJ.objects(7).data='skin3';
        	OBJ.objects(8).type='usemtl';
        	OBJ.objects(8).data='skin3';
        	OBJ.objects(9).type='f';
        	OBJ.objects(9).data.vertices=Faces_V(length(Flow_Faces_V_Positive)+length(Flow_Faces_V_Negative)+1:end,:);
        	OBJ.objects(9).data.normal=Faces_V(length(Flow_Faces_V_Positive)+length(Flow_Faces_V_Negative)+1:end,:);
            
            % Exported file name
            ExportName=strcat('UpstreamBody_Y_Vel_',sprintf('%02d',NumberDataFiles),'.obj');    %Input 12
            
            % Full export file name and loctaion
            FullFileExport=fullfile(FileDir,ExportFolder,ExportName);
            
            % Creates the .OBJ file and places it in the specified location
            write_wobj(OBJ,FullFileExport);
            sprintf(ExportName, ' has been created.\n')
            
            clear ExportName FullFileExport
            
            %% Creating Material Information for .MTL File (Z-Velocity)
            fprintf(1, 'Creating material info for .mtl file (z-velocity)...\n');
            clear material
            
            % Flow Color Info
            material(1).type='newmtl';
            material(1).data='skin1';
            material(2).type='Ka';
        	material(2).data=[0 0 0];
        	material(3).type='Kd';
        	material(3).data=[0.8 0 0.8];   % Purple is positive velocity
        	material(4).type='Ks';
        	material(4).data=[1 1 1];
        	material(5).type='illum';
        	material(5).data=2;
        	material(6).type='Ns';
        	material(6).data=27;
            
            material(7).type='newmtl';
            material(7).data='skin2';
            material(8).type='Ka';
        	material(8).data=[0 0 0];
        	material(9).type='Kd';
        	material(9).data=[1 1 0.2];   % Yellow is negative velocity
        	material(10).type='Ks';
        	material(10).data=[1 1 1];
        	material(11).type='illum';
        	material(11).data=2;
        	material(12).type='Ns';
        	material(12).data=27;
            
            % Panel Color Info
            material(13).type='newmtl';
            material(13).data='skin3';
            material(14).type='Ka';
        	material(14).data=[0 0 0];
        	material(15).type='Kd';
        	material(15).data=[0 0 0.3]; % Picthing panel color is dark navy
        	material(16).type='Ks';
        	material(16).data=[1 1 1];
        	material(17).type='illum';
        	material(17).data=2;
        	material(18).type='Ns';
        	material(18).data=27;
            
            
            %% Creating Surface Information for .OBJ File (Z-Velocity)
            fprintf(1, 'Creating surface info for .obj file (z-velocity)...\n');
            clear OBJ
            
            
            OBJ.vertices = Vertices_W;
        	OBJ.vertices_normal = Isonorms_W;
        	OBJ.material = material;
            
            % Flow OBJ info
        	OBJ.objects(1).type='g';
        	OBJ.objects(1).data='skin1';
        	OBJ.objects(2).type='usemtl';
        	OBJ.objects(2).data='skin1';
        	OBJ.objects(3).type='f';
        	OBJ.objects(3).data.vertices=Faces_W(1:length(Flow_Faces_W_Positive),:);
        	OBJ.objects(3).data.normal=Faces_W(1:length(Flow_Faces_W_Positive),:);
            
            OBJ.objects(4).type='g';
        	OBJ.objects(4).data='skin2';
        	OBJ.objects(5).type='usemtl';
        	OBJ.objects(5).data='skin2';
        	OBJ.objects(6).type='f';
        	OBJ.objects(6).data.vertices=Faces_W(length(Flow_Faces_W_Positive)+1:length(Flow_Faces_W_Positive)+length(Flow_Faces_W_Negative),:);
        	OBJ.objects(6).data.normal=Faces_W(length(Flow_Faces_W_Positive)+1:length(Flow_Faces_W_Positive)+length(Flow_Faces_W_Negative),:);
            
            % Panel OBJ info
            OBJ.objects(7).type='g';
        	OBJ.objects(7).data='skin3';
        	OBJ.objects(8).type='usemtl';
        	OBJ.objects(8).data='skin3';
        	OBJ.objects(9).type='f';
        	OBJ.objects(9).data.vertices=Faces_W(length(Flow_Faces_W_Positive)+length(Flow_Faces_W_Negative)+1:end,:);
        	OBJ.objects(9).data.normal=Faces_W(length(Flow_Faces_W_Positive)+length(Flow_Faces_W_Negative)+1:end,:);
            
            % Exported file name
            ExportName=strcat('UpstreamBody_Z_Vel_',sprintf('%02d',NumberDataFiles),'.obj');    %Input 12
            sprintf(ExportName, ' has been created.\n')
            
            % Full export file name and loctaion
            FullFileExport=fullfile(FileDir,ExportFolder,ExportName);
            
            % Creates the .OBJ file and places it in the specified location
            write_wobj(OBJ,FullFileExport);
            
            clear ExportName FullFileExport

        toc
    end %for NumberDataFiles
end %function create_obj_example.m

%-------------------------------------------------------------------
function [dudx, dudy, dudz, dvdx, dvdy, dvdz, dwdx, dwdy, dwdz, q] = GradientCalcs( x, y, z, u, v, w)

    dudx = zeros(length(x),length(y),length(z));
    dvdx = zeros(length(x),length(y),length(z)); 
    dwdx = zeros(length(x),length(y),length(z));
    dudy = zeros(length(x),length(y),length(z)); 
    dvdy = zeros(length(x),length(y),length(z)); 
    dwdy = zeros(length(x),length(y),length(z));
    dudz = zeros(length(x),length(y),length(z)); 
    dvdz = zeros(length(x),length(y),length(z)); 
    dwdz = zeros(length(x),length(y),length(z));
    q    = zeros(length(x),length(y),length(z));

    for i=1:length(x)
        for j=1:length(y)
            for k=1:length(z)
                if ( i==1 )
                    dudx(i,j,k) =(u(i+1,j,k)-u(i,j,k))/(x(i+1)-x(i));
                    dvdx(i,j,k) =(v(i+1,j,k)-v(i,j,k))/(x(i+1)-x(i));
                    dwdx(i,j,k) =(w(i+1,j,k)-w(i,j,k))/(x(i+1)-x(i));
                elseif ( i==length(x) )
                    dudx(i,j,k) =(u(i,j,k)-u(i-1,j,k))/(x(i)-x(i-1));
                    dvdx(i,j,k) =(v(i,j,k)-v(i-1,j,k))/(x(i)-x(i-1));
                    dwdx(i,j,k) =(w(i,j,k)-w(i-1,j,k))/(x(i)-x(i-1));
                else
                    dudx(i,j,k) =(u(i+1,j,k)-u(i-1,j,k))/(x(i+1)-x(i-1));
                    dvdx(i,j,k) =(v(i+1,j,k)-v(i-1,j,k))/(x(i+1)-x(i-1));
                    dwdx(i,j,k) =(w(i+1,j,k)-w(i-1,j,k))/(x(i+1)-x(i-1));
                end %if

                if ( j==1 )
                    dudy(i,j,k) =(u(i,j+1,k)-u(i,j,k))/(y(j+1)-y(j));
                    dvdy(i,j,k) =(v(i,j+1,k)-v(i,j,k))/(y(j+1)-y(j));
                    dwdy(i,j,k) =(w(i,j+1,k)-w(i,j,k))/(y(j+1)-y(j));
                elseif ( j==length(y) )
                    dudy(i,j,k) =(u(i,j,k)-u(i,j-1,k))/(y(j)-y(j-1));
                    dvdy(i,j,k) =(v(i,j,k)-v(i,j-1,k))/(y(j)-y(j-1));
                    dwdy(i,j,k) =(w(i,j,k)-w(i,j-1,k))/(y(j)-y(j-1));
                else
                    dudy(i,j,k) =(u(i,j+1,k)-u(i,j-1,k))/(y(j+1)-y(j-1));
                    dvdy(i,j,k) =(v(i,j+1,k)-v(i,j-1,k))/(y(j+1)-y(j-1));
                    dwdy(i,j,k) =(w(i,j+1,k)-w(i,j-1,k))/(y(j+1)-y(j-1));
                end %if
                
                if ( k==1 )
                    dudz(i,j,k) =(u(i,j,k+1)-u(i,j,k))/(z(k+1)-z(k));
                    dvdz(i,j,k) =(v(i,j,k+1)-v(i,j,k))/(z(k+1)-z(k));
                    dwdz(i,j,k) =(w(i,j,k+1)-w(i,j,k))/(z(k+1)-z(k));
                elseif ( k==length(z) )
                    dudz(i,j,k) =(u(i,j,k)-u(i,j,k-1))/(z(k)-z(k-1));
                    dvdz(i,j,k) =(v(i,j,k)-v(i,j,k-1))/(z(k)-z(k-1));
                    dwdz(i,j,k) =(w(i,j,k)-w(i,j,k-1))/(z(k)-z(k-1));
                else
                    dudz(i,j,k) =(u(i,j,k+1)-u(i,j,k-1))/(z(k+1)-z(k-1));
                    dvdz(i,j,k) =(v(i,j,k+1)-v(i,j,k-1))/(z(k+1)-z(k-1));
                    dwdz(i,j,k) =(w(i,j,k+1)-w(i,j,k-1))/(z(k+1)-z(k-1));
                end %if

                % build s
                s(1,1)=            dudx(i,j,k);
                s(1,2)=        .5*dudy(i,j,k)+.5*dvdx(i,j,k);
                s(1,3)=        .5*dudz(i,j,k)+.5*dwdx(i,j,k);
                s(2,1)=        .5*dvdx(i,j,k)+.5*dudy(i,j,k);
                s(2,2)=            dvdy(i,j,k);
                s(2,3)=        .5*dvdz(i,j,k)+.5*dwdy(i,j,k);
                s(3,1)=        .5*dwdx(i,j,k)+.5*dudz(i,j,k);
                s(3,2)=        .5*dwdy(i,j,k)+.5*dvdz(i,j,k);
                s(3,3)=            dwdz(i,j,k);

                %build omega
                o(1,1)=                   0;
                o(1,2)=           .5*dudy(i,j,k)-.5*dvdx(i,j,k);
                o(1,3)=           .5*dudz(i,j,k)-.5*dwdx(i,j,k);
                o(2,1)=           .5*dvdx(i,j,k)-.5*dudy(i,j,k);
                o(2,2)=                   0;
                o(2,3)=           .5*dvdz(i,j,k)-.5*dwdy(i,j,k);
                o(3,1)=           .5*dwdx(i,j,k)-.5*dudz(i,j,k);
                o(3,2)=           .5*dwdy(i,j,k)-.5*dvdz(i,j,k);
                o(3,3)=                   0;

                %computes q
                s_t      = s';
                o_t      = o';
                sst      = s*s_t;
                oot      = o*o_t;
                t_s      = trace(sst);
                t_o      = trace(oot);
                q(i,j,k) = .5*(t_o-t_s);

            end %for k
        end %for j
    end %for i
end %function Gradient Calcs

%-------------------------------------------------------------------

function [ FinShape ] = PanelGeneration(NumberDataFiles, FileDir)
        % Panel Position Data
        PanelFile=['Panel\Original\Trapezoid_Panel_Grid_',sprintf('%02d', NumberDataFiles),'.dat']; 
        DATA=fullfile(FileDir,PanelFile);

        fprintf(1, 'Reading in data... ');
        fid = fopen(DATA);
        ints = fread(fid,5,'int32',0);
%         ints = fread(fid,6,'int32',0)

        ox     = ints(2); %#ok<NASGU> <-- Suppresses error message.
        oy     = ints(3); %#ok<NASGU>
        oz     = ints(4); %#ok<NASGU>
        nblcks = ints(5); %#ok<NASGU>
        
        tag    = fread(fid,1,'int32',0);
        datain = fread(fid,tag/4,'single', 0);
        tag2   = fread(fid,1,'int32',0); %#ok<NASGU> <-- Suppresses error message.
        toc

        fclose(fid);
        
        y = datain(1:12);           % fin length
        x = datain(13:24);          % fin width
        z = datain(25:36);          % fin height

        %         IsoPoints = zeros(12,3);
        % 
        %         IsoPoints(:,1) = x;
        %         IsoPoints(:,2) = y;
        %         IsoPoints(:,3) = z; 

        FinShape=alphaShape(x, y, z);
        FinShape.Alpha=3;   % Larger alpha radius captures full form of shape opposed to parts of the figure being lost

end %function PandelGeneration( )

%-------------------------------------------------------------------