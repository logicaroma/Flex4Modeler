<?php
	$method = $_REQUEST['method'];
	$file = $_REQUEST['filename'];
	
	if($method == 'save'){ // save a temporary file for downloading
		$content = $_POST['content'];
		$handler = fopen($file, 'w');
		fwrite($handler,$content);
		fclose($handler);
		exit;
	} else if($method == 'download') { // download and delete the temporary file
		if(!is_readable($file)) exit("File is unreadable");
		
		$size = filesize($file);
		$name = "$file.dae";
		$mime_type = "model/x3d+binary";
		
		@ob_end_clean();

		// required for IE, otherwise Content-Disposition may be ignored
		if(ini_get('zlib.output_compression'))
			ini_set('zlib.output_compression', 'Off');
			
		header('Content-Type: ' . $mime_type);
		header('Content-Disposition: attachment; filename="'.$name.'"');
		header("Content-Transfer-Encoding: binary");
		header('Accept-Ranges: bytes');

		/* The three lines below basically make the download non-cacheable */
		header("Cache-control: private");
		header('Pragma: private');
		header("Expires: Mon, 26 Jul 1997 05:00:00 GMT");
		
		if(isset($_SERVER['HTTP_RANGE']))
		{
			list($a, $range) = explode("=",$_SERVER['HTTP_RANGE'],2);
			list($range) = explode(",",$range,2);
			list($range, $range_end) = explode("-", $range);
			$range=intval($range);
			if(!$range_end) {
				$range_end=$size-1;
			} else {
				$range_end=intval($range_end);
			}

			$new_length = $range_end-$range+1;
			header("HTTP/1.1 206 Partial Content");
			header("Content-Length: $new_length");
			header("Content-Range: bytes $range-$range_end/$size");
		} else {
			$new_length=$size;
			header("Content-Length: ".$size);
		}

		/* output the file itself */
		$chunksize = 1*(1024*1024); //you may want to change this
		$bytes_send = 0;
		if ($f = fopen($file, 'r'))
		{
			if(isset($_SERVER['HTTP_RANGE']))
				fseek($f, $range);

			while(!feof($f) && (!connection_aborted()) && ($bytes_send<$new_length)){
				$buffer = fread($f, $chunksize);
				print($buffer); //echo($buffer); // is also possible
				flush();
				$bytes_send += strlen($buffer);
			}
			fclose($f);
			$deleted = unlink($file);
		} else {
			exit("File could not be opened");
		}
		
		exit();
	}
?>