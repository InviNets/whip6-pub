/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2016 InviNets Sp z o.o.
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files. If you do not find these files, copies can be found by writing
 * to technology@invinets.com.
 */
import java.io.IOException;
import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.Inet6Address;
import java.net.InetAddress;
import java.net.SocketException;
import java.net.UnknownHostException;



/**
 * A simple server for the UDPEcho application.
 * 
 * The command-line parameters are respectively:
 * - local IPv6 address
 * - local port number (optional, by default 10001)
 * 
 * @author Konrad Iwanicki
 */
public class Server {

	public static final int DEFAULT_PORT = 10001;
	public static final int MAX_PACKET_SIZE = 2048;
	
	private static void printInfo() {
		System.out.println("whip6: Warsaw High-performance IPv6");
		System.out.println("Simple UDP over IPv6 server for the UDPEcho application");
		System.out.println("Copyright (C) 2013-2014, WhipTronics");
		System.out.println();
	}
	
	private static void printUsage() {
		System.err.println("Usage:");
		System.err.println("  java " + Server.class.getCanonicalName() +
				" <local_ipv6_addr> [<local_port>]");
		System.err.println();
	}
	
	/**
	 * The main method.
	 * @param args The program arguments.
	 */
	public static void main(String[] args) {
		printInfo();
		
		if (args.length < 1 || args.length > 2) {
			System.err.println("ERROR: Invalid arguments!");
			System.err.println();
			printUsage();
			System.exit(1);
		}
		
		int portNo = DEFAULT_PORT;
		if (args.length == 2) {
			try {
				portNo = Integer.parseInt(args[1]);
				if (portNo < 1024 || portNo > 65535) {
					throw new NumberFormatException();
				}
			} catch (NumberFormatException e) {
				System.err.println("ERROR: Invalid port number \"" +
						args[1] + "\"!");
				System.err.println();
				printUsage();
				System.exit(1);
			}
		}
		
		Inet6Address addr = null;
		try {
			InetAddress addr4 = Inet6Address.getByName(args[0]);
			if (! (addr4 instanceof Inet6Address)) {
				throw new UnknownHostException();
			}
			addr = (Inet6Address)addr4;
		} catch (UnknownHostException e) {
			System.err.println("ERROR: Invalid IPv6 address \"" +
					args[0] + "\"!");
			System.err.println();
			printUsage();
			System.exit(1);
		}
		
		try {
			DatagramSocket socket = new DatagramSocket(portNo, addr);
			DatagramPacket rpacket = new DatagramPacket(new byte[MAX_PACKET_SIZE], MAX_PACKET_SIZE);
			DatagramPacket spacket = new DatagramPacket(new byte[MAX_PACKET_SIZE], MAX_PACKET_SIZE);
			while (true) {
				socket.receive(rpacket);
				String decoded = new String(rpacket.getData(), 0, rpacket.getLength(), "UTF-8");
				System.out.println("Received a " + rpacket.getLength() +
						"-byte packet: \"" + decoded + "\"!");
				spacket.setAddress(rpacket.getAddress());
				spacket.setPort(rpacket.getPort());
				System.arraycopy(rpacket.getData(), rpacket.getOffset(), spacket.getData(), 0, rpacket.getLength());
				spacket.setLength(rpacket.getLength());
				socket.send(spacket);
			}
		} catch (SocketException e) {
			System.err.println("ERROR: Socket exception: " + e.getMessage() + "!");
			System.err.println();
			printUsage();
			System.exit(1);
		} catch (IOException e) {
			System.err.println("ERROR: I/O exception: " + e.getMessage() + "!");
			System.err.println();
			printUsage();
			System.exit(1);
		}
	}

}
